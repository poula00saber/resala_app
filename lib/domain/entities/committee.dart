// ============================================
// FILE: lib/domain/entities/committee.dart
// ============================================

class Committee {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  Committee({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });
}
