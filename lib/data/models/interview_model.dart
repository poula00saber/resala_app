// ============================================
// FILE: lib/data/models/interview_model.dart
// UPDATED: Now extends Interview entity
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/interview.dart';

class InterviewModel extends Interview {
  InterviewModel({
    required super.id,
    required super.volunteerId,
    required super.volunteerName,
    required super.interviewDate,
    required super.answers,
    super.passed,
    super.totalGrade,
    required super.status,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InterviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final answers = data['answers'] as Map<String, dynamic>? ?? {};

    return InterviewModel(
      id: doc.id,
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      interviewDate: (data['interviewDate'] as Timestamp).toDate(),
      answers: answers.map((key, value) => MapEntry(key, value.toString())),
      passed: data['passed'],
      totalGrade: data['totalGrade'],
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // ... rest of the methods remain the same
  Map<String, dynamic> toFirestore() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'interviewDate': Timestamp.fromDate(interviewDate),
      'answers': answers,
      'passed': passed,
      'totalGrade': totalGrade,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InterviewModel copyWith({
    String? id,
    String? volunteerId,
    String? volunteerName,
    DateTime? interviewDate,
    Map<String, String>? answers,
    bool? passed,
    int? totalGrade,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      interviewDate: interviewDate ?? this.interviewDate,
      answers: answers ?? this.answers,
      passed: passed ?? this.passed,
      totalGrade: totalGrade ?? this.totalGrade,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
