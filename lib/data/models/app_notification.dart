class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? recipeId;
  final String? sharedRecipePlanId;
  final String? decisionRequestId;
  final String? recipeSuggestionId;
  final String? decisionShareId;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.recipeId,
    required this.sharedRecipePlanId,
    required this.decisionRequestId,
    required this.recipeSuggestionId,
    required this.decisionShareId,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'].toString(),
      type: map['type']?.toString() ?? 'general',
      title: map['title']?.toString() ?? 'Benachrichtigung',
      body: map['body']?.toString() ?? '',
      recipeId: map['recipe_id']?.toString(),
      sharedRecipePlanId: map['shared_recipe_plan_id']?.toString(),
      decisionRequestId: map['decision_request_id']?.toString(),
      recipeSuggestionId: map['recipe_suggestion_id']?.toString(),
      decisionShareId: map['decision_share_id']?.toString(),
      readAt: map['read_at'] == null ? null : DateTime.parse(map['read_at'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}
