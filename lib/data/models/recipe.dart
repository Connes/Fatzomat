class Recipe {
  final String? id;
  final String name;
  final String description;
  final int servings;
  final String servingsUnit;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final String difficulty;
  final String category;
  final List<String> foodTags;
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
    this.servingsUnit = 'Personen',
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.difficulty,
    this.category = '',
    this.foodTags = const <String>[],
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
        servingsUnit: _normalizeServingsUnit(map['servings_unit'] ?? map['servingsUnit']),
        prepTimeMinutes: _int(map['prep_time_minutes']),
        cookTimeMinutes: _int(map['cook_time_minutes']),
        difficulty: map['difficulty']?.toString() ?? 'Einfach',
        category: map['category']?.toString().trim() ?? '',
        foodTags: normalizeFoodTags(map['food_tags'] ?? map['foodTags']),
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
    final target = targetServings.clamp(1, 999).toInt();
    final base = servings <= 0 ? 1 : servings;
    return Recipe(
      id: id,
      name: name,
      description: description,
      servings: target,
      servingsUnit: servingsUnit,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      difficulty: difficulty,
      category: category,
      foodTags: List<String>.from(foodTags),
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
        'servings_unit': servingsUnit,
          'prep_time_minutes': prepTimeMinutes,
          'cook_time_minutes': cookTimeMinutes,
          'difficulty': difficulty,
          'category': category,
          'food_tags': foodTags,
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
        'servings_unit': servingsUnit,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'difficulty': difficulty,
        'category': category,
        'food_tags': foodTags,
        'instructions': instructions,
        'image_url': imageUrl,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
      };

  static const supportedFoodTags = <String>['Schwein', 'Rind', 'Huhn', 'Fisch', 'Vegetarisch'];

  static List<String> normalizeFoodTags(dynamic value) {
    if (value is! List) return const <String>[];
    final normalized = value
        .map((item) => item.toString().trim())
        .where((item) => supportedFoodTags.contains(item))
        .toSet();
    if (normalized.contains('Vegetarisch')) {
      normalized.removeAll({'Schwein', 'Rind', 'Huhn', 'Fisch'});
    }
    return supportedFoodTags.where(normalized.contains).toList(growable: false);
  }

  static String _normalizeServingsUnit(dynamic value) {
    final unit = value?.toString().trim().toLowerCase();
    return unit == 'stück' || unit == 'stueck' || unit == 'stücke' || unit == 'stuecke'
        ? 'Stück'
        : 'Personen';
  }

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
  final bool quantityIsOptional;
  final String? section;

  const RecipeIngredient({
    this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isUserSelected = false,
    this.isAdditional = false,
    this.isQualitative = false,
    this.quantityIsOptional = false,
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
        quantityIsOptional: map['quantity_is_optional'] == true,
        section: map['section']?.toString().trim().isEmpty == true ? null : map['section']?.toString().trim(),
      );

  /// A qualitative flag must not hide an explicitly measured ingredient.
  /// Legacy imports sometimes set is_qualitative while still storing a unit
  /// such as EL or g; in that case the numeric amount is meaningful.
  bool get hidesQuantity => quantityIsOptional || (isQualitative && unit.trim().isEmpty);

  RecipeIngredient scaledTo(num factor) => RecipeIngredient(
        foodId: foodId,
        name: name,
        quantity: quantity * factor,
        unit: unit,
        isUserSelected: isUserSelected,
        isAdditional: isAdditional,
        isQualitative: isQualitative,
        quantityIsOptional: quantityIsOptional,
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
        'quantity_is_optional': quantityIsOptional,
        'section': section,
      };
}
