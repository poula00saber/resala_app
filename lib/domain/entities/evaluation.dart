// ============================================
// FILE: lib/domain/entities/evaluation.dart (UPDATED)
// ============================================

class Evaluation {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final String evaluatorName;
  final String month;
  final int year;
  final int rating; // 1-10
  final String? notes;
  final DateTime createdAt;

  Evaluation({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.evaluatorName,
    required this.month,
    required this.year,
    required this.rating,
    this.notes,
    required this.createdAt,
  });
}


// ============================================
// FILE: lib/main.dart (UPDATE - Add EvaluationProvider)
// ============================================

// Add this to your MultiProvider in main.dart:

/*

*/