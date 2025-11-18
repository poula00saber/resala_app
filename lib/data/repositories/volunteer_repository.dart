// ============================================
// FILE: lib/data/repositories/volunteer_repository.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';
import '../../core/constants/firebase_constants.dart';

class VolunteerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all volunteers (Stream for real-time updates)
  Stream<List<VolunteerModel>> getAllVolunteers() {
    return _firestore
        .collection(FirebaseConstants.volunteersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VolunteerModel.fromFirestore(doc))
            .toList());
  }

  // Get volunteer by ID
  Future<VolunteerModel?> getVolunteerById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return VolunteerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting volunteer: $e');
      return null;
    }
  }

  // Get volunteers by IDs
  Future<List<VolunteerModel>> getVolunteersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final docs = await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      return docs.docs
          .map((doc) => VolunteerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting volunteers by IDs: $e');
      return [];
    }
  }

  // Create volunteer
  Future<String?> createVolunteer(VolunteerModel volunteer) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .add(volunteer.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating volunteer: $e');
      return null;
    }
  }

  // Update volunteer
  Future<bool> updateVolunteer(String id, VolunteerModel volunteer) async {
    try {
      await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .doc(id)
          .update(volunteer.toFirestore());
      return true;
    } catch (e) {
      print('Error updating volunteer: $e');
      return false;
    }
  }

  // Delete volunteer
  Future<bool> deleteVolunteer(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting volunteer: $e');
      return false;
    }
  }

  // Search volunteers
  Stream<List<VolunteerModel>> searchVolunteers(String query) {
    return _firestore
        .collection(FirebaseConstants.volunteersCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final volunteers = snapshot.docs
          .map((doc) => VolunteerModel.fromFirestore(doc))
          .toList();

      if (query.isEmpty) return volunteers;

      return volunteers.where((volunteer) {
        return volunteer.name.toLowerCase().contains(query.toLowerCase()) ||
            volunteer.phone.contains(query);
      }).toList();
    });
  }
}