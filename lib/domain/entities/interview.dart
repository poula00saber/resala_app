// ============================================
// FILE: lib/domain/entities/interview.dart
// ============================================

class Interview {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final DateTime interviewDate;
  final Map<String, String> answers;
  final bool? passed;
  final int? totalGrade;
  final String status; // pending, passed, failed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interview({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.interviewDate,
    required this.answers,
    this.passed,
    this.totalGrade,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
