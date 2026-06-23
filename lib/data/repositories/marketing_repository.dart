// ============================================
// FILE: lib/data/repositories/marketing_repository.dart
// Repository for marketing/story operations
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketing_model.dart';
import '../../services/operation_log_service.dart';

class MarketingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'marketing';

  // Get all marketing records
  Stream<List<MarketingModel>> getAllMarketing() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketingModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get marketing by volunteer ID
  Stream<List<MarketingModel>> getMarketingByVolunteer(String volunteerId) {
    return _firestore
        .collection(_collection)
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketingModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Check if volunteer has marketing record for month/year
  Future<bool> hasExistingRecord(
    String volunteerId,
    int month,
    int year,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('volunteerId', isEqualTo: volunteerId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking existing record: $e');
      return false;
    }
  }

  // Add marketing record
  Future<String?> addMarketing({
    required String volunteerId,
    required String volunteerName,
    required int month,
    required int year,
  }) async {
    try {
      final marketing = MarketingModel(
        id: '',
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        month: month,
        year: year,
        createdAt: DateTime.now(),
      );
      final docRef = await _firestore
          .collection(_collection)
          .add(marketing.toFirestore());
      await OperationLogService.log(
        action: 'create',
        entityType: 'marketing',
        entityId: docRef.id,
        entityName: volunteerName,
        details: {'month': month, 'year': year},
      );
      return docRef.id;
    } catch (e) {
      print('Error adding marketing: $e');
      return null;
    }
  }

  // Get marketing count
  Future<int> getMarketingCount({
    String? volunteerId,
    int? month,
    int? year,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (volunteerId != null) {
        query = query.where('volunteerId', isEqualTo: volunteerId);
      }
      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting marketing count: $e');
      return 0;
    }
  }

  // Delete marketing record
  Future<bool> deleteMarketing(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'marketing',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting marketing: $e');
      return false;
    }
  }
}
