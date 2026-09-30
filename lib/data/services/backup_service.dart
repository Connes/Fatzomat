import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import '../repositories/food_repository.dart';
import '../repositories/recipe_repository.dart';

/// Exports the personal data that is useful to recover the private collection.
///
/// This is intentionally an export-only backup in v1. It never includes auth
/// credentials, session tokens, or connection codes. Shared live state remains
/// in Supabase and is not serialized as if it were an offline restore format.
class BackupService {
  final SupabaseClient? _client;
  final RecipeRepository? _recipeRepository;
  final FoodRepository? _foodRepository;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  BackupService({
    SupabaseClient? client,
    RecipeRepository? recipeRepository,
    FoodRepository? foodRepository,
  })  : _client = client,
        _recipeRepository = recipeRepository,
        _foodRepository = foodRepository;

  Future<Uri?> exportPersonalBackup() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Keine Supabase-Sitzung vorhanden.');
    }

    final preferences = await (_foodRepository ?? FoodRepository(client: client)).preferences();
    final recipes = await (_recipeRepository ?? RecipeRepository(client: client)).savedRecipeModels();

    final payload = buildPayload(
      profile: null,
      preferences: preferences,
      recipes: recipes,
    );
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );

    return FilePicker.saveFile(
      dialogTitle: 'Schmackofatz-Sicherung speichern',
      fileName: 'schmackofatz_backup.json',
      bytes: bytes,
      mimeType: 'application/json',
    );
  }

  static Map<String, dynamic> buildPayload({
    required Map<String, dynamic>? profile,
    required Map<String, String> preferences,
    required List<Recipe> recipes,
  }) {
    return {
      'format': 'schmackofatz_backup',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'profile': profile,
      'preferences': preferences,
      'recipes': recipes.map((recipe) => recipe.toTogetherRecipeJson()).toList(growable: false),
    };
  }
}
