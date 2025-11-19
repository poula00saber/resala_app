// ============================================
// FILE: lib/data/models/committee_model.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/committee.dart';

class CommitteeModel extends Committee {
  CommitteeModel({
    required super.id,
    required super.name,
    super.description,
    required super.isActive,
    required super.createdAt,
  });

  factory CommitteeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommitteeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }
}
