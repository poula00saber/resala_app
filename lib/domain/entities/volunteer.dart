// ============================================
// FILE: lib/domain/entities/volunteer.dart
// UPDATED: Added hasTshirt field
// ============================================

class Volunteer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? nationalId;
  final bool hasInterview;
  final DateTime createdAt;

  Volunteer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.nationalId,
    required this.hasInterview,
    required this.createdAt,
  });
}
