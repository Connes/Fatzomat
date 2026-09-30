class Recipe {
  final String? id;
  final String name;
  final String description;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final String difficulty;
  final List<String> instructions;
  final List<RecipeIngredient> ingredients;
  final String? imageUrl;
  final String? imagePath;
  final String? createdBy;
  final String? savedBy;
  final DateTime? savedAt;
  final DateTime? updatedAt;

  const Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.instructions,
    required this.ingredients,
    this.imageUrl,
    this.imagePath,
    this.createdBy,
    this.savedBy,
    this.savedAt,
    this.updatedAt,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
        id: map['id']?.toString(),
        name: map['name']?.toString() ?? 'Rezept',
        description: map['description']?.toString() ?? '',
        servings: _int(map['servings']),
        prepTimeMinutes: _int(map['prep_time_minutes']),
        cookTimeMinutes: _int(map['cook_time_minutes']),
        difficulty: map['difficulty']?.toString() ?? 'Einfach',
        instructions: _strings(map['instructions'] ?? map['steps']),
        ingredients: ((map['ingredients'] ?? map['recipe_ingredients']) as List? ?? const [])
            .whereType<Map>()
            .map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        imageUrl: map['image_url']?.toString(),
        imagePath: map['image_path']?.toString(),
        createdBy: map['created_by']?.toString(),
        savedBy: map['_saved_by']?.toString(),
        savedAt: map['_saved_at'] == null ? null : DateTime.tryParse(map['_saved_at'].toString()),
        updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'].toString()),
      );

  Recipe scaledTo(int targetServings) {
    final target = targetServings.clamp(1, 12).toInt();
    final base = servings <= 0 ? 1 : servings;
    return Recipe(
      id: id,
      name: name,
      description: description,
      servings: target,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      difficulty: difficulty,
      instructions: List<String>.from(instructions),
      ingredients: ingredients.map((ingredient) => ingredient.scaledTo(target / base)).toList(),
      imageUrl: imageUrl,
      imagePath: imagePath,
      createdBy: createdBy,
      savedBy: savedBy,
      savedAt: savedAt,
      updatedAt: updatedAt,
    );
  }

  /// Stable interchange format used by the manual importer and ChatGPT.
  Map<String, dynamic> toTogetherRecipeJson() => {
        'format': 'together_recipe',
        'version': 1,
        'recipe': {
          'title': name,
          'description': description.isEmpty ? null : description,
          'servings': servings,
          'prep_time_minutes': prepTimeMinutes,
          'cook_time_minutes': cookTimeMinutes,
          'difficulty': difficulty,
          'ingredients': ingredients
              .map((ingredient) => {
                    'food_id': ingredient.foodId,
                    'name': ingredient.name,
                    'amount': ingredient.quantity,
                    'unit': ingredient.unit,
                    'is_user_selected': ingredient.isUserSelected,
                    'is_additional': ingredient.isAdditional,
                    'is_qualitative': ingredient.isQualitative,
                    'section': ingredient.section,
                  })
              .toList(growable: false),
          'steps': instructions,
          'image_url': imagePath == null ? imageUrl : null,
        },
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'servings': servings,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'difficulty': difficulty,
        'instructions': instructions,
        'image_url': imageUrl,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
      };

  static int _int(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
  static List<String> _strings(dynamic value) => value is List ? value.map((e) => e.toString()).toList() : const [];
}

class RecipeIngredient {
  final String? foodId;
  final String name;
  final num quantity;
  final String unit;
  final bool isUserSelected;
  final bool isAdditional;
  final bool isQualitative;
  final String? section;

  const RecipeIngredient({
    this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isUserSelected = false,
    this.isAdditional = false,
    this.isQualitative = false,
    this.section,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) => RecipeIngredient(
        foodId: map['food_id']?.toString(),
        name: map['name']?.toString() ?? '',
        quantity: map['quantity'] is num ? map['quantity'] as num : num.tryParse(map['quantity']?.toString() ?? '') ?? 0,
        unit: map['unit']?.toString() ?? '',
        isUserSelected: map['is_user_selected'] == true,
        isAdditional: map['is_additional'] == true,
        isQualitative: map['is_qualitative'] == true,
        section: map['section']?.toString().trim().isEmpty == true ? null : map['section']?.toString().trim(),
      );

  RecipeIngredient scaledTo(num factor) => RecipeIngredient(
        foodId: foodId,
        name: name,
        quantity: quantity * factor,
        unit: unit,
        isUserSelected: isUserSelected,
        isAdditional: isAdditional,
        isQualitative: isQualitative,
        section: section,
      );

  Map<String, dynamic> toMap() => {
        'food_id': foodId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'is_user_selected': isUserSelected,
        'is_additional': isAdditional,
        'is_qualitative': isQualitative,
        'section': section,
      };
}
