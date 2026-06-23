// ============================================
// FILE: lib/data/repositories/volunteer_repository.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/volunteer_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class VolunteerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all volunteers (Stream for real-time updates)
  Stream<List<VolunteerModel>> getAllVolunteers() {
    return _firestore
        .collection(FirebaseConstants.volunteersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VolunteerModel.fromFirestore(doc))
              .toList(),
        );
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

  // Get volunteer by email
  Future<VolunteerModel?> getVolunteerByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return VolunteerModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting volunteer by email: $e');
      return null;
    }
  }

  // Get volunteers by IDs
  // Firestore whereIn supports max 30 items per query, so we batch
  Future<List<VolunteerModel>> getVolunteersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final List<VolunteerModel> allVolunteers = [];

      // Split into chunks of 30 to avoid Firestore whereIn limit
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
        final docs = await _firestore
            .collection(FirebaseConstants.volunteersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        allVolunteers.addAll(
          docs.docs.map((doc) => VolunteerModel.fromFirestore(doc)),
        );
      }

      return allVolunteers;
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
      await OperationLogService.log(
        action: 'create',
        entityType: 'volunteer',
        entityId: docRef.id,
        entityName: volunteer.name,
        details: {
          'phone': volunteer.phone,
          'committeeId': volunteer.committeeId,
          'educationalLevel': volunteer.educationalLevel,
        },
      );
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
      await OperationLogService.log(
        action: 'update',
        entityType: 'volunteer',
        entityId: id,
        entityName: volunteer.name,
        details: {
          'phone': volunteer.phone,
          'committeeId': volunteer.committeeId,
          'educationalLevel': volunteer.educationalLevel,
        },
      );
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
      await OperationLogService.log(
        action: 'delete',
        entityType: 'volunteer',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting volunteer: $e');
      return false;
    }
  }

  // Add this method to your VolunteerRepository class
  Future<bool> updateVolunteerLevel(String volunteerId, String newLevel) async {
    try {
      await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .doc(volunteerId)
          .update({
            'educationalLevel': newLevel,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await OperationLogService.log(
        action: 'update',
        entityType: 'volunteer_level',
        entityId: volunteerId,
        details: {'educationalLevel': newLevel},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating volunteer level: $e');
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
