// ============================================
// FILE: lib/data/models/promotion_model.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionRequirement {
  final String id;
  final String volunteerId;
  final String currentLevel;
  final String nextLevel;
  final List<Requirement> requirements;
  final DateTime createdAt;

  PromotionRequirement({
    required this.id,
    required this.volunteerId,
    required this.currentLevel,
    required this.nextLevel,
    required this.requirements,
    required this.createdAt,
  });

  // Calculate completion status
  bool get isComplete => requirements.every((req) => req.isCompleted);
  int get completedCount => requirements.where((req) => req.isCompleted).length;
  int get totalCount => requirements.length;

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'currentLevel': currentLevel,
      'nextLevel': nextLevel,
      'requirements': requirements.map((req) => req.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Map
  factory PromotionRequirement.fromMap(Map<String, dynamic> map, String id) {
    final requirementsList = (map['requirements'] as List)
        .map((item) => Requirement.fromMap(item as Map<String, dynamic>))
        .toList();

    return PromotionRequirement(
      id: id,
      volunteerId: map['volunteerId'] ?? '',
      currentLevel: map['currentLevel'] ?? '',
      nextLevel: map['nextLevel'] ?? '',
      requirements: requirementsList,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // ADD THIS COPYWITH METHOD
  PromotionRequirement copyWith({
    String? id,
    String? volunteerId,
    String? currentLevel,
    String? nextLevel,
    List<Requirement>? requirements,
    DateTime? createdAt,
  }) {
    return PromotionRequirement(
      id: id ?? this.id,
      volunteerId: volunteerId ?? this.volunteerId,
      currentLevel: currentLevel ?? this.currentLevel,
      nextLevel: nextLevel ?? this.nextLevel,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Requirement {
  final String id;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;

  Requirement({
    required this.id,
    required this.description,
    required this.isCompleted,
    this.completedAt,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  // Create from Map
  factory Requirement.fromMap(Map<String, dynamic> map) {
    return Requirement(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Copy with changes
  Requirement copyWith({
    String? id,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Requirement(
      id: id ?? this.id,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
