class RecipeSuggestion {
  final String id;
  final String connectionId;
  final String recipeId;
  final String suggestedBy;
  final String suggestedTo;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? senderName;
  final String? copiedRecipeId;

  const RecipeSuggestion({
    required this.id,
    required this.connectionId,
    required this.recipeId,
    required this.suggestedBy,
    required this.suggestedTo,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
    this.senderName,
    this.copiedRecipeId,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  factory RecipeSuggestion.fromMap(Map<String, dynamic> map) => RecipeSuggestion(
    id: map['id'].toString(),
    connectionId: map['connection_id'].toString(),
    recipeId: map['recipe_id'].toString(),
    suggestedBy: map['suggested_by'].toString(),
    suggestedTo: map['suggested_to'].toString(),
    status: map['status']?.toString() ?? 'pending',
    createdAt: DateTime.parse(map['created_at'].toString()),
    respondedAt: map['responded_at'] == null ? null : DateTime.parse(map['responded_at'].toString()),
    senderName: map['sender_name']?.toString(),
    copiedRecipeId: map['copied_recipe_id']?.toString(),
  );
}
