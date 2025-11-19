// ============================================
// FILE 1: lib/data/repositories/committee_repository.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/committee_model.dart';
import '../../core/constants/firebase_constants.dart';

class CommitteeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all committees
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

  // Get active committees only
  Stream<List<CommitteeModel>> getActiveCommittees() {
    return _firestore
        .collection(FirebaseConstants.committeesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommitteeModel.fromFirestore(doc))
              .toList(),
        );
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
      return true;
    } catch (e) {
      print('Error deleting committee: $e');
      return false;
    }
  }
}
