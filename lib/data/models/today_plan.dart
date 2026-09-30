class TodayPlan {
  final String id;
  final String? recipeId;
  final String decisionType;
  final String? decisionValue;
  final String status;
  final int servings;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final bool isShared;
  final bool isSharedAccepted;

  const TodayPlan({
    required this.id,
    this.recipeId,
    this.decisionType = 'recipe',
    this.decisionValue,
    required this.status,
    required this.servings,
    required this.name,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.isShared = false,
    this.isSharedAccepted = false,
  });

  bool get isRecipe => decisionType == 'recipe' && recipeId != null;

  String get displayTitle {
    if (isRecipe) return name;
    if (decisionType == 'order') return 'Wir bestellen · ${decisionValue ?? 'Auswahl'}';
    if (decisionType == 'dine_out') return 'Wir gehen essen · ${decisionValue ?? 'Auswahl'}';
    if (decisionType == 'surprise') return 'Überrasch mich · ${decisionValue ?? 'Heute entscheidet der Zufall'}';
    return name;
  }

  factory TodayPlan.fromMap(Map<String, dynamic> map) {
    final recipe = map['recipes'] is Map
        ? Map<String, dynamic>.from(map['recipes'] as Map)
        : const <String, dynamic>{};
    final recipeId = map['recipe_id']?.toString();
    final decisionType = map['decision_type']?.toString() ?? 'recipe';
    return TodayPlan(
      id: map['id'].toString(),
      recipeId: recipeId?.isEmpty == true ? null : recipeId,
      decisionType: decisionType,
      decisionValue: map['decision_value']?.toString(),
      status: map['status']?.toString() ?? 'planned',
      servings: (map['servings'] as num?)?.toInt() ?? (recipe['servings'] as num?)?.toInt() ?? 2,
      name: recipe['name']?.toString() ?? 'Heute',
      description: recipe['description']?.toString(),
      imageUrl: recipe['image_url']?.toString(),
      imagePath: recipe['image_path']?.toString(),
      isShared: map['is_shared'] == true,
      isSharedAccepted: map['is_shared_accepted'] == true,
    );
  }
}
