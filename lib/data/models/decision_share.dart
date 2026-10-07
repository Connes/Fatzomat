class DecisionShare {
  final String id;
  final String connectionId;
  final String senderId;
  final String recipientId;
  final String messageType;
  final DateTime planDate;
  final String? decisionType;
  final String? decisionValue;
  final String? decisionName;
  final String? imageUrl;
  final String? recipeId;
  final int? servings;
  final String? sourcePlanId;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  const DecisionShare({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.recipientId,
    required this.messageType,
    required this.planDate,
    required this.decisionType,
    required this.decisionValue,
    required this.decisionName,
    required this.imageUrl,
    required this.recipeId,
    required this.servings,
    required this.sourcePlanId,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.cancelledAt,
    required this.createdAt,
  });

  bool get isAsk => messageType == 'ask';
  bool get isShare => messageType == 'share';

  factory DecisionShare.fromMap(Map<String, dynamic> map) => DecisionShare(
        id: map['id'].toString(),
        connectionId: map['connection_id'].toString(),
        senderId: map['sender_id'].toString(),
        recipientId: map['recipient_id'].toString(),
        messageType: map['message_type']?.toString() ?? 'ask',
        planDate: DateTime.parse(map['plan_date'].toString()),
        decisionType: map['decision_type']?.toString(),
        decisionValue: map['decision_value']?.toString(),
        decisionName: map['decision_name']?.toString(),
        imageUrl: map['image_url']?.toString(),
        recipeId: map['recipe_id']?.toString(),
        servings: (map['servings'] as num?)?.toInt(),
        sourcePlanId: map['source_plan_id']?.toString(),
        acceptedAt: map['accepted_at'] == null ? null : DateTime.tryParse(map['accepted_at'].toString()),
        rejectedAt: map['rejected_at'] == null ? null : DateTime.tryParse(map['rejected_at'].toString()),
        cancelledAt: map['cancelled_at'] == null ? null : DateTime.tryParse(map['cancelled_at'].toString()),
        createdAt: DateTime.parse(map['created_at'].toString()),
      );
