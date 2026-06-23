// ============================================
// FILE: lib/data/repositories/evaluation_repository.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evaluation_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class EvaluationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get evaluations for a specific volunteer

  Stream<List<EvaluationModel>> getEvaluationsForVolunteer(String volunteerId) {
    print('🔍 Getting evaluations for volunteer: $volunteerId'); // Debug log

    return _firestore
        .collection(FirebaseConstants.evaluationsCollection)
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Found ${snapshot.docs.length} evaluations'); // Debug log

          return snapshot.docs.map((doc) {
            print('📄 Evaluation data: ${doc.data()}'); // Debug log
            return EvaluationModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Get all evaluations
  Stream<List<EvaluationModel>> getAllEvaluations() {
    return _firestore
        .collection(FirebaseConstants.evaluationsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EvaluationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get latest evaluation for a volunteer
  Future<EvaluationModel?> getLatestEvaluation(String volunteerId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.evaluationsCollection)
          .where('volunteerId', isEqualTo: volunteerId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        return EvaluationModel.fromFirestore(doc.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting latest evaluation: $e');
      return null;
    }
  }

  // Create evaluation
  Future<String?> createEvaluation(EvaluationModel evaluation) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.evaluationsCollection)
          .add(evaluation.toFirestore());
      await OperationLogService.log(
        action: 'create',
        entityType: 'evaluation',
        entityId: docRef.id,
        entityName: evaluation.evaluationName,
        details: {
          'volunteerId': evaluation.volunteerId,
          'volunteerName': evaluation.volunteerName,
          'rating': evaluation.rating,
        },
      );
      return docRef.id;
    } catch (e) {
      print('Error creating evaluation: $e');
      return null;
    }
  }

  // Update evaluation
  Future<bool> updateEvaluation(String id, EvaluationModel evaluation) async {
    try {
      await _firestore
          .collection(FirebaseConstants.evaluationsCollection)
          .doc(id)
          .update(evaluation.toFirestore());
      await OperationLogService.log(
        action: 'update',
        entityType: 'evaluation',
        entityId: id,
        entityName: evaluation.evaluationName,
        details: {
          'volunteerId': evaluation.volunteerId,
          'rating': evaluation.rating,
        },
      );
      return true;
    } catch (e) {
      print('Error updating evaluation: $e');
      return false;
    }
  }

  // Delete evaluation
  Future<bool> deleteEvaluation(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.evaluationsCollection)
          .doc(id)
          .delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'evaluation',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting evaluation: $e');
      return false;
    }
  }

  // Get average rating for a volunteer
  Future<double> getAverageRating(String volunteerId) async {
    try {
      final docs = await _firestore
          .collection(FirebaseConstants.evaluationsCollection)
          .where('volunteerId', isEqualTo: volunteerId)
          .get();

      if (docs.docs.isEmpty) return 0.0;

      final ratings = docs.docs
          .map((doc) => (doc.data()['rating'] ?? 0) as int)
          .toList();
      final sum = ratings.reduce((a, b) => a + b);
      return sum / ratings.length;
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }
}
