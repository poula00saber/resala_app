// ============================================
// FILE: lib/domain/entities/volunteer.dart
// UPDATED: Fixed constructor parameter order
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
  final int? age;
  final String? committeeId;
  final String? committeeName;
  final String? secondaryCommitteeId;
  final String? secondaryCommitteeName;
  final String? birthDate;
  final String? gender;
  final String? educationalLevel;
  final String? university;
  final String? profileImage;
  final bool hasTshirt;
  final bool miniCampCompleted;

  Volunteer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.nationalId,
    required this.hasInterview,
    required this.createdAt,
    this.age,
    this.committeeId,
    this.committeeName,
    this.secondaryCommitteeId,
    this.secondaryCommitteeName,
    this.birthDate,
    this.gender,
    this.educationalLevel,
    this.university,
    this.profileImage,
    this.hasTshirt = false,
    this.miniCampCompleted = false,
  });
}
