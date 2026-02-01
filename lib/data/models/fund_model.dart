// ============================================
// FILE: lib/data/models/fund_model.dart
// Model for fund/donation records
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FundModel {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final double amount;
  final int month;
  final int year;
  final bool isWithdrawal;
  final String? withdrawalReason;
  final DateTime createdAt;

  FundModel({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.amount,
    required this.month,
    required this.year,
    this.isWithdrawal = false,
    this.withdrawalReason,
    required this.createdAt,
  });

  factory FundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FundModel(
      id: doc.id,
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      month: data['month'] ?? 1,
      year: data['year'] ?? DateTime.now().year,
      isWithdrawal: data['isWithdrawal'] ?? false,
      withdrawalReason: data['withdrawalReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'amount': amount,
      'month': month,
      'year': year,
      'isWithdrawal': isWithdrawal,
      'withdrawalReason': withdrawalReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
