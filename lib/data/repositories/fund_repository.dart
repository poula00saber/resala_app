// ============================================
// FILE: lib/data/repositories/fund_repository.dart
// Repository for fund/donation operations
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fund_model.dart';

class FundRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'funds';

  // Get all fund records
  Stream<List<FundModel>> getAllFunds() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => FundModel.fromFirestore(doc)).toList(),
        );
  }

  // Get funds by volunteer ID
  Stream<List<FundModel>> getFundsByVolunteer(String volunteerId) {
    return _firestore
        .collection(_collection)
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => FundModel.fromFirestore(doc)).toList(),
        );
  }

  // Get funds by month and year
  Future<List<FundModel>> getFundsByMonthYear(int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();
      return snapshot.docs.map((doc) => FundModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting funds by month/year: $e');
      return [];
    }
  }

  // Check if volunteer has fund record for month/year
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
          .where('isWithdrawal', isEqualTo: false)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking existing record: $e');
      return false;
    }
  }

  // Add fund record (donation)
  Future<String?> addFund({
    required String volunteerId,
    required String volunteerName,
    required double amount,
    required int month,
    required int year,
  }) async {
    try {
      final fund = FundModel(
        id: '',
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        amount: amount,
        month: month,
        year: year,
        isWithdrawal: false,
        createdAt: DateTime.now(),
      );
      final docRef = await _firestore
          .collection(_collection)
          .add(fund.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding fund: $e');
      return null;
    }
  }

  // Add withdrawal
  Future<String?> addWithdrawal({
    required String volunteerId,
    required String volunteerName,
    required double amount,
    required String reason,
  }) async {
    try {
      final now = DateTime.now();
      final fund = FundModel(
        id: '',
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        amount: amount,
        month: now.month,
        year: now.year,
        isWithdrawal: true,
        withdrawalReason: reason,
        createdAt: now,
      );
      final docRef = await _firestore
          .collection(_collection)
          .add(fund.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding withdrawal: $e');
      return null;
    }
  }

  // Get total fund amount
  Future<double> getTotalFundAmount({int? month, int? year}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      final snapshot = await query.get();
      double total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final isWithdrawal = data['isWithdrawal'] ?? false;

        if (isWithdrawal) {
          total -= amount;
        } else {
          total += amount;
        }
      }

      return total;
    } catch (e) {
      print('Error getting total fund: $e');
      return 0;
    }
  }

  // Delete fund record
  Future<bool> deleteFund(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting fund: $e');
      return false;
    }
  }
}
