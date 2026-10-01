import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import '../../core/app_exception.dart';
import '../../core/auth_session_service.dart';
import '../../core/recipe_collection_events.dart';
import '../services/recipe_image_service.dart';

class RecipeDuplicateException extends AppException {
  final String recipeId;

  const RecipeDuplicateException(this.recipeId)
      : super('Dieses Rezept gibt es bereits in eurer Sammlung.');
}

class RecipeRepository {
  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  RecipeRepository({SupabaseClient? client}) : _client = client;

  Map<String, dynamic> _recipePayload(Recipe recipe) => {
        'name': recipe.name,
        'description': recipe.description,
        'servings': recipe.servings,
        'prep_time_minutes': recipe.prepTimeMinutes,
        'cook_time_minutes': recipe.cookTimeMinutes,
        'difficulty': recipe.difficulty,
        'instructions': recipe.instructions,
        'image_url': recipe.imagePath == null ? recipe.imageUrl : null,
      };

  List<Map<String, dynamic>> _ingredientPayload(Recipe recipe) => recipe.ingredients
      .map((i) => {
            'food_id': i.foodId,
            'name': i.name,
            'quantity': i.quantity,
            'unit': i.unit,
            'is_user_selected': i.isUserSelected,
            'is_additional': i.isAdditional,
            'is_qualitative': i.isQualitative,
            'section': i.section,
          })
      .toList(growable: false);

  Future<Recipe?> findDuplicateRecipe(Recipe recipe) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();
    final result = await client.rpc(
      'find_shared_recipe_duplicate',
      params: {
        'p_recipe': _recipePayload(recipe),
        'p_ingredients': _ingredientPayload(recipe),
      },
    );
    final id = result?.toString().trim() ?? '';
    if (id.isEmpty || id == 'null') return null;
    return getRecipeModel(id);
  }

  Future<String> saveRecipeModel(Recipe recipe, {bool allowDuplicate = false}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();

    final result = await client.rpc(
      'create_shared_recipe',
      params: {
        'p_recipe': _recipePayload(recipe),
        'p_ingredients': _ingredientPayload(recipe),
        'p_allow_duplicate': allowDuplicate,
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    final created = map['created'] == true;
    if (!created) {
      final duplicateId = map['duplicate_recipe_id']?.toString().trim() ?? '';
      if (duplicateId.isNotEmpty) throw RecipeDuplicateException(duplicateId);
      throw const BackendException('Das Rezept konnte nicht gespeichert werden.');
    }
    final id = map['recipe_id']?.toString().trim() ?? '';
    if (id.isEmpty) throw const BackendException('Das gespeicherte Rezept hat keine gültige ID.');
    RecipeCollectionEvents.notifyChanged();
    return id;
  }

  Future<String> updateSharedRecipe(Recipe recipe) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();
    final id = recipe.id?.trim() ?? '';
    if (id.isEmpty) throw const ValidationException('Keine Rezept-ID vorhanden.');

    final duplicate = await findDuplicateRecipe(recipe);
    if (duplicate?.id != null && duplicate!.id != id) {
      throw RecipeDuplicateException(duplicate.id!);
    }

    final result = await client.rpc(
      'update_shared_recipe',
      params: {
        'p_recipe_id': id,
        'p_recipe': _recipePayload(recipe),
        'p_ingredients': _ingredientPayload(recipe),
      },
    );
    final updatedId = result?.toString().trim() ?? '';
    if (updatedId.isEmpty) throw const BackendException('Das Rezept konnte nicht aktualisiert werden.');
    RecipeCollectionEvents.notifyChanged();
    return updatedId;
  }

  Future<String> addFavoriteRecipe({
    required String name,
    String description = '',
    List<String> instructions = const [],
    List<Map<String, dynamic>> ingredients = const [],
  }) async {
    if (client.auth.currentUser == null) throw const AuthenticationException();
    final result = await client.rpc('add_favorite_recipe', params: {
      'p_name': name.trim(),
      'p_description': description.trim(),
      'p_instructions': instructions,
      'p_ingredients': ingredients,
    });
    final id = result.toString();
    RecipeCollectionEvents.notifyChanged();
    return id;
  }

  Future<bool> removeRecipeFromCollection(String id) async {
    final recipe = await client
        .from('recipes')
        .select('image_path')
        .eq('id', id)
        .maybeSingle();
    final imagePath = recipe?['image_path']?.toString().trim() ?? '';

    final result = await client.rpc(
      'remove_recipe_from_collection',
      params: {'p_recipe_id': id},
    );
    final removed = result == true;
    if (removed) {
      if (imagePath.isNotEmpty) {
        await _deleteImageIfUnreferenced(imagePath);
      }
      RecipeCollectionEvents.notifyChanged();
    }
    return removed;
  }

  Future<List<Recipe>> savedRecipeModels() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await client
        .from('recipes')
        .select('id,created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url,image_path,created_at,recipe_ingredients(*)')
        // Keep the collection compatible with currently deployed databases.
        // `recipes.updated_at` is introduced by the later shared-recipe
        // collection migration and is not required to display saved recipes.
        .order('created_at', ascending: false);

    final recipes = (rows as List)
        .whereType<Map>()
        .map((row) => Recipe.fromMap(Map<String, dynamic>.from(row)))
        .where((recipe) => recipe.id != null)
        .toList(growable: false);
    return Future.wait(recipes.map(_withResolvedImage));
  }

  Future<Recipe> getRecipeModel(String id) async {
    final row = await client
        .from('recipes')
        .select('*,recipe_ingredients(*)')
        .eq('id', id)
        .single();
    return _withResolvedImage(Recipe.fromMap(Map<String, dynamic>.from(row)));
  }

  Future<Recipe> _withResolvedImage(Recipe recipe) async {
    final path = recipe.imagePath?.trim() ?? '';
    if (path.isEmpty) return recipe;
    final signedUrl = await RecipeImageService(client: client).resolveSignedUrl(path);
    return Recipe(
      id: recipe.id,
      name: recipe.name,
      description: recipe.description,
      servings: recipe.servings,
      prepTimeMinutes: recipe.prepTimeMinutes,
      cookTimeMinutes: recipe.cookTimeMinutes,
      difficulty: recipe.difficulty,
      instructions: recipe.instructions,
      ingredients: recipe.ingredients,
      imageUrl: signedUrl ?? recipe.imageUrl,
      imagePath: path,
      createdBy: recipe.createdBy,
      savedBy: recipe.savedBy,
      savedAt: recipe.savedAt,
      updatedAt: recipe.updatedAt,
    );
  }

  Future<void> _deleteImageIfUnreferenced(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return;
    final refs = await client.from('recipes').select('id').eq('image_path', normalized).limit(2);
    if ((refs as List).isNotEmpty) return;
    try {
      await RecipeImageService(client: client).delete(normalized);
    } catch (_) {
      // A stale storage object must not make a successful recipe operation fail.
    }
  }

  bool canManageRecipeImage(Recipe recipe) {
    final userId = client.auth.currentUser?.id;
    return userId != null && recipe.createdBy == userId;
  }

  Future<Recipe> setRecipeImage(String recipeId, RecipeImageUpload upload) async {
    await AuthSessionService.ensureValidSession(client: client);
    final current = await client
        .from('recipes')
        .select('image_path')
        .eq('id', recipeId)
        .single();
    final oldPath = current['image_path']?.toString().trim() ?? '';
    await AuthSessionService.runWithRefresh(
      client: client,
      action: () => client.from('recipes').update({
        'image_path': upload.path,
        'image_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', recipeId),
    );
    if (oldPath.isNotEmpty && oldPath != upload.path) {
      await _deleteImageIfUnreferenced(oldPath);
    }
    RecipeCollectionEvents.notifyChanged();
    return getRecipeModel(recipeId);
  }

  Future<void> removeRecipeImage(String recipeId) async {
    await AuthSessionService.ensureValidSession(client: client);
    final current = await client
        .from('recipes')
        .select('image_path')
        .eq('id', recipeId)
        .single();
    final path = current['image_path']?.toString().trim() ?? '';
    await client.from('recipes').update({
      'image_path': null,
      'image_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', recipeId);
    if (path.isNotEmpty) {
      await _deleteImageIfUnreferenced(path);
    }
    RecipeCollectionEvents.notifyChanged();
  }

  Future<void> saveExistingRecipe(String recipeId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();
    final id = recipeId.trim();
    if (id.isEmpty) throw const ValidationException('Keine Recipe-ID vorhanden.');
    await client.from('recipe_saves').upsert({
      'recipe_id': id,
      'user_id': userId,
    }, onConflict: 'recipe_id,user_id');
    RecipeCollectionEvents.notifyChanged();
  }

  Future<bool> isSaved(String recipeId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await client
        .from('recipe_saves')
        .select('recipe_id')
        .eq('recipe_id', recipeId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> unsaveRecipe(String recipeId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthenticationException();
    await client.from('recipe_saves').delete().eq('recipe_id', recipeId).eq('user_id', userId);
    RecipeCollectionEvents.notifyChanged();
  }

  Future<Recipe> getRecipe(String id) => getRecipeModel(id);
}
