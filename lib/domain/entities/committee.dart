// ============================================
// FILE: lib/domain/entities/committee.dart
// ============================================

class Committee {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final String? leaderId;
  final String? leaderName;
  final String? coLeaderId;
  final String? coLeaderName;

  Committee({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    this.leaderId,
    this.leaderName,
    this.coLeaderId,
    this.coLeaderName,
  });
}
