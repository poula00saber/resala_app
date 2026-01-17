// ============================================
// FILE: lib/domain/entities/promotion.dart
// ============================================

class Promotion {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final String fromLevel;
  final String toLevel;
  final DateTime promotionDate;
  final List<PromotionRequirement> requirements;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.fromLevel,
    required this.toLevel,
    required this.promotionDate,
    required this.requirements,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });
}

class PromotionRequirement {
  final String id;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;

  PromotionRequirement({
    required this.id,
    required this.description,
    required this.isCompleted,
    this.completedAt,
  });
}
