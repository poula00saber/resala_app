// ============================================
// FILE: lib/data/models/marketing_model.dart
// Model for marketing/story records
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MarketingModel {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final int month;
  final int year;
  final DateTime createdAt;

  MarketingModel({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  factory MarketingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarketingModel(
      id: doc.id,
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      month: data['month'] ?? 1,
      year: data['year'] ?? DateTime.now().year,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'month': month,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
