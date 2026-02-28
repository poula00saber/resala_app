// ============================================
// FILE: lib/data/models/committee_model.dart
// UPDATED: Added copyWith method
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/committee.dart';

class CommitteeModel extends Committee {
  CommitteeModel({
    required super.id,
    required super.name,
    required super.isActive,
    required super.createdAt,
  });

  factory CommitteeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommitteeModel(
      id: doc.id,
      name: data['name'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }

  // ADD THIS COPYWITH METHOD
  CommitteeModel copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CommitteeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
