class PersonalHistoryEntry {
  final String id;
  final String? recipeId;
  final String? planId;
  final String action;
  final String source;
  final DateTime createdAt;
  final String? recipeName;
  final String? imageUrl;
  final String? imagePath;

  const PersonalHistoryEntry({
    required this.id,
    this.recipeId,
    this.planId,
    required this.action,
    required this.source,
    required this.createdAt,
    this.recipeName,
    this.imageUrl,
    this.imagePath,
  });

  factory PersonalHistoryEntry.fromMap(Map<String, dynamic> map) {
    final recipe = map['recipes'] is Map ? Map<String, dynamic>.from(map['recipes'] as Map) : const <String, dynamic>{};
    return PersonalHistoryEntry(
      id: map['id'].toString(),
      recipeId: map['recipe_id']?.toString(),
      planId: map['plan_id']?.toString(),
      action: map['action']?.toString() ?? 'unknown',
      source: map['source']?.toString() ?? 'today',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      recipeName: recipe['name']?.toString(),
      imageUrl: recipe['image_url']?.toString(),
      imagePath: recipe['image_path']?.toString(),
    );
  }

  String get label => switch (action) {
        'selected' => 'Für heute ausgewählt',
        'replaced' => 'Heute-Entscheidung geändert',
        'servings_changed' => 'Portionen geändert',
        'status_changed' => 'Status geändert',
        'cancelled' => 'Heute-Entscheidung entfernt',
        _ => 'Persönliche Entscheidung',
      };
}
