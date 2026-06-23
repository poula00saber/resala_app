// ============================================
// FILE: lib/data/repositories/interview_repository.dart
// FIXED: Added duplicate check in createInterview
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resala/data/models/interview_model.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class InterviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all interviews
  Stream<List<InterviewModel>> getAllInterviews() {
    return _firestore
        .collection(FirebaseConstants.interviewsCollection)
        .orderBy('interviewDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InterviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get interviews by volunteer ID
  Future<List<InterviewModel>> getInterviewsByVolunteerId(
    String volunteerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .where('volunteerId', isEqualTo: volunteerId)
          .orderBy('interviewDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InterviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting interviews by volunteer ID: $e');
      return [];
    }
  }

  // Get interview by ID
  Future<InterviewModel?> getInterviewById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return InterviewModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting interview: $e');
      return null;
    }
  }

  // Create new interview - FIXED: Now checks for duplicates
  Future<String?> createInterview(InterviewModel interview) async {
    try {
      // SAFETY CHECK: Verify no existing interview for this volunteer
      final existingInterviews = await getInterviewsByVolunteerId(
        interview.volunteerId,
      );

      if (existingInterviews.isNotEmpty) {
        print(
          '⚠️ Interview already exists for volunteer ${interview.volunteerId}',
        );
        // Return existing interview ID instead of creating duplicate
        return existingInterviews.first.id;
      }

      // No existing interview, safe to create new one
      final docRef = await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .add(interview.toFirestore());

      await OperationLogService.log(
        action: 'create',
        entityType: 'interview',
        entityId: docRef.id,
        entityName: interview.volunteerName,
        details: {'volunteerId': interview.volunteerId},
      );

      print('✅ Created new interview for volunteer ${interview.volunteerId}');
      return docRef.id;
    } catch (e) {
      print('Error creating interview: $e');
      return null;
    }
  }

  // Update interview
  Future<bool> updateInterview(String id, InterviewModel interview) async {
    try {
      await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .doc(id)
          .update(interview.toFirestore());
      await OperationLogService.log(
        action: 'update',
        entityType: 'interview',
        entityId: id,
        entityName: interview.volunteerName,
        details: {'status': interview.status},
      );
      return true;
    } catch (e) {
      print('Error updating interview: $e');
      return false;
    }
  }

  // Update interview answers
  Future<bool> updateInterviewAnswers({
    required String interviewId,
    required Map<String, String> answers,
    bool? passed,
    int? totalGrade,
    String? notes,
  }) async {
    try {
      String status;
      if (passed == true) {
        status = FirebaseConstants.interviewStatusPassed;
      } else if (passed == false) {
        status = FirebaseConstants.interviewStatusFailed;
      } else {
        status = FirebaseConstants.interviewStatusPending;
      }

      await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .doc(interviewId)
          .update({
            'answers': answers,
            if (passed != null) 'passed': passed,
            if (totalGrade != null) 'totalGrade': totalGrade,
            if (notes != null) 'notes': notes,
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await OperationLogService.log(
        action: 'update',
        entityType: 'interview_answers',
        entityId: interviewId,
        details: {
          if (passed != null) 'passed': passed,
          if (totalGrade != null) 'totalGrade': totalGrade,
        },
      );
      return true;
    } catch (e) {
      print('Error updating interview answers: $e');
      return false;
    }
  }

  // Delete interview
  Future<bool> deleteInterview(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .doc(id)
          .delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'interview',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting interview: $e');
      return false;
    }
  }

  // Search interviews by volunteer name
  Stream<List<InterviewModel>> searchInterviews(String query) {
    return _firestore
        .collection(FirebaseConstants.interviewsCollection)
        .orderBy('volunteerName')
        .snapshots()
        .map((snapshot) {
          final interviews = snapshot.docs
              .map((doc) => InterviewModel.fromFirestore(doc))
              .toList();

          if (query.isEmpty) return interviews;

          return interviews.where((interview) {
            return interview.volunteerName.toLowerCase().contains(
              query.toLowerCase(),
            );
          }).toList();
        });
  }

  // Get interviews by status
  Stream<List<InterviewModel>> getInterviewsByStatus(String status) {
    return _firestore
        .collection(FirebaseConstants.interviewsCollection)
        .where('status', isEqualTo: status)
        .orderBy('interviewDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InterviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get volunteers without interviews
  Future<List<dynamic>> getVolunteersWithoutInterviews(
    List<dynamic> allVolunteers,
  ) async {
    try {
      final interviewsSnapshot = await _firestore
          .collection(FirebaseConstants.interviewsCollection)
          .get();

      final interviewedVolunteerIds = interviewsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['volunteerId'])
          .toSet();

      return allVolunteers
          .where((volunteer) => !interviewedVolunteerIds.contains(volunteer.id))
          .toList();
    } catch (e) {
      print('Error getting volunteers without interviews: $e');
      return allVolunteers;
    }
  }
}
