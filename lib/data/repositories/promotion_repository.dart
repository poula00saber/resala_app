// ============================================
// FILE: lib/data/repositories/promotion_repository.dart
// FIXED VERSION
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/promotion_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class PromotionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PromotionRequirement>> watchAllPromotionRequirements() {
    return _firestore
        .collection(FirebaseConstants.promotionRequirementsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PromotionRequirement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get or create promotion requirements for a volunteer at current level
  Future<PromotionRequirement?> getPromotionRequirements(
    String volunteerId,
    String currentLevel,
    String nextLevel,
  ) async {
    try {
      // Try to find existing requirements
      final query = await _firestore
          .collection(FirebaseConstants.promotionRequirementsCollection)
          .where('volunteerId', isEqualTo: volunteerId)
          .where('currentLevel', isEqualTo: currentLevel)
          .where('nextLevel', isEqualTo: nextLevel)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Return existing requirements
        return PromotionRequirement.fromMap(
          query.docs.first.data(),
          query.docs.first.id,
        );
      } else {
        // Create new requirements with default questions
        return await _createDefaultRequirements(
          volunteerId,
          currentLevel,
          nextLevel,
        );
      }
    } catch (e) {
      debugPrint('Error getting promotion requirements: $e');
      return null;
    }
  }

  /// Create default requirements based on level
  Future<PromotionRequirement?> _createDefaultRequirements(
    String volunteerId,
    String currentLevel,
    String nextLevel,
  ) async {
    try {
      final requirements = _getDefaultRequirementsForLevel(currentLevel);

      final docRef = await _firestore
          .collection(FirebaseConstants.promotionRequirementsCollection)
          .add({
            'volunteerId': volunteerId,
            'currentLevel': currentLevel,
            'nextLevel': nextLevel,
            'requirements': requirements.map((req) => req.toMap()).toList(),
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      await OperationLogService.log(
        action: 'create',
        entityType: 'promotion_requirements',
        entityId: docRef.id,
        entityName: volunteerId,
        details: {'currentLevel': currentLevel, 'nextLevel': nextLevel},
      );

      return PromotionRequirement(
        id: docRef.id,
        volunteerId: volunteerId,
        currentLevel: currentLevel,
        nextLevel: nextLevel,
        requirements: requirements,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating default requirements: $e');
      return null;
    }
  }

  // Get default requirements based on current level
  List<Requirement> _getDefaultRequirementsForLevel(String level) {
    final requirements =
        FirebaseConstants.promotionRequirements[level] ??
        ['متطلب 1', 'متطلب 2', 'متطلب 3', 'متطلب 4'];

    return requirements.asMap().entries.map((entry) {
      final index = entry.key;
      final description = entry.value;
      return Requirement(
        id: (index + 1).toString(),
        description: description,
        isCompleted: false,
      );
    }).toList();
  }

  // Update requirement status
  Future<bool> updateRequirementStatus(
    String promotionId,
    String requirementId,
    bool isCompleted,
  ) async {
    try {
      // Get current document
      final doc = await _firestore
          .collection(FirebaseConstants.promotionRequirementsCollection)
          .doc(promotionId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final requirementsData = data['requirements'] as List<dynamic>;

      // Update specific requirement
      final updatedRequirements = requirementsData.map((item) {
        final reqData = item as Map<String, dynamic>;
        if (reqData['id'] == requirementId) {
          return {
            ...reqData,
            'isCompleted': isCompleted,
            'completedAt': isCompleted ? Timestamp.now() : null,
          };
        }
        return item;
      }).toList();

      // Update in Firestore
      await _firestore
          .collection(FirebaseConstants.promotionRequirementsCollection)
          .doc(promotionId)
          .update({
            'requirements': updatedRequirements,
            'updatedAt': Timestamp.now(),
          });

      await OperationLogService.log(
        action: 'update',
        entityType: 'promotion_requirement',
        entityId: promotionId,
        details: {'requirementId': requirementId, 'isCompleted': isCompleted},
      );

      return true;
    } catch (e) {
      debugPrint('Error updating requirement status: $e');
      return false;
    }
  }

  // Delete promotion requirements (when promoted)
  Future<bool> deletePromotionRequirements(String promotionId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.promotionRequirementsCollection)
          .doc(promotionId)
          .delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'promotion_requirements',
        entityId: promotionId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting promotion requirements: $e');
      return false;
    }
  }
}
