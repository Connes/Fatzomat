class DecisionRequest {
  final String id;
  final String connectionId;
  final String createdBy;
  final String assignedTo;
  final String status;
  final String? decisionMode;
  final String? resultType;
  final String? resultId;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const DecisionRequest({
    required this.id,
    required this.connectionId,
    required this.createdBy,
    required this.assignedTo,
    required this.status,
    required this.decisionMode,
    required this.resultType,
    required this.resultId,
    required this.createdAt,
    required this.resolvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isResolved => status == 'resolved';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  factory DecisionRequest.fromMap(Map<String, dynamic> map) {
    return DecisionRequest(
      id: map['id'].toString(),
      connectionId: map['connection_id'].toString(),
      createdBy: map['created_by'].toString(),
      assignedTo: map['assigned_to'].toString(),
      status: map['status']?.toString() ?? 'pending',
      decisionMode: map['decision_mode']?.toString(),
      resultType: map['result_type']?.toString(),
      resultId: map['result_id']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      resolvedAt: map['resolved_at'] == null
          ? null
          : DateTime.parse(map['resolved_at'].toString()),
    );
  }
}
