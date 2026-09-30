class ConnectionInfo {
  final String id;
  final String code;
  final int memberCount;

  const ConnectionInfo({required this.id, required this.code, required this.memberCount});

  bool get isConnected => memberCount >= 2;
  bool get waitingForPartner => memberCount == 1;

  factory ConnectionInfo.fromMap(Map<String, dynamic> map) => ConnectionInfo(
        id: map['connection_id'].toString(),
        code: map['connection_code']?.toString() ?? '',
        memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
      );
}
