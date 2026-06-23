// ============================================
// FILE: lib/data/repositories/committee_repository.dart
// NEW FILE
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/committee_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class CommitteeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all committees (Stream for real-time updates)
  Stream<List<CommitteeModel>> getAllCommittees() {
    return _firestore
        .collection(FirebaseConstants.committeesCollection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommitteeModel.fromFirestore(doc))
              .toList(),
        );
  }

  // FILE: lib/data/repositories/committee_repository.dart
  Stream<List<CommitteeModel>> getActiveCommittees() {
    print('🔄 CommitteeRepository: getActiveCommittees() called');

    try {
      return _firestore
          .collection(FirebaseConstants.committeesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            print(
              '📊 CommitteeRepository: Got ${snapshot.docs.length} committees',
            );

            final committees = snapshot.docs.map((doc) {
              print('📄 Committee ID: ${doc.id}, Data: ${doc.data()}');
              return CommitteeModel.fromFirestore(doc);
            }).toList();

            print(
              '✅ CommitteeRepository: Successfully parsed ${committees.length} committees',
            );
            return committees;
          })
          .handleError((error) {
            print('❌ CommitteeRepository ERROR: $error');
            print('Stack trace: ${StackTrace.current}');
            throw error;
          });
    } catch (e) {
      print('❌ CommitteeRepository EXCEPTION: $e');
      rethrow;
    }
  }

  // Get committee by ID
  Future<CommitteeModel?> getCommitteeById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.committeesCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return CommitteeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting committee: $e');
      return null;
    }
  }

  // Create committee
  Future<String?> createCommittee(CommitteeModel committee) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.committeesCollection)
          .add(committee.toFirestore());
      await OperationLogService.log(
        action: 'create',
        entityType: 'committee',
        entityId: docRef.id,
        entityName: committee.name,
      );
      return docRef.id;
    } catch (e) {
      print('Error creating committee: $e');
      return null;
    }
  }

  // Update committee
  Future<bool> updateCommittee(String id, CommitteeModel committee) async {
    try {
      await _firestore
          .collection(FirebaseConstants.committeesCollection)
          .doc(id)
          .update(committee.toFirestore());
      await OperationLogService.log(
        action: 'update',
        entityType: 'committee',
        entityId: id,
        entityName: committee.name,
        details: {'isActive': committee.isActive},
      );
      return true;
    } catch (e) {
      print('Error updating committee: $e');
      return false;
    }
  }

  // Delete committee
  Future<bool> deleteCommittee(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.committeesCollection)
          .doc(id)
          .delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'committee',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting committee: $e');
      return false;
    }
  }

  // Toggle committee active status
  Future<bool> toggleCommitteeStatus(String id, bool isActive) async {
    try {
      await _firestore
          .collection(FirebaseConstants.committeesCollection)
          .doc(id)
          .update({
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await OperationLogService.log(
        action: 'update',
        entityType: 'committee_status',
        entityId: id,
        details: {'isActive': isActive},
      );
      return true;
    } catch (e) {
      print('Error toggling committee status: $e');
      return false;
    }
  }
}
