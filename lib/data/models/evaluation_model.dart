// // ============================================
// // FILE: lib/data/models/evaluation_model.dart
// // ============================================

// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../domain/entities/evaluation.dart';

// class EvaluationModel extends Evaluation {
//   EvaluationModel({
//     required super.id,
//     required super.volunteerId,
//     required super.volunteerName,
//     required super.evaluatorName,
//     required super.month,
//     required super.year,
//     required super.ratings,
//     required super.totalScore,
//     required super.averageScore,
//     super.notes,
//     required super.createdAt,
//   });

//   factory EvaluationModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     final ratingsData = data['ratings'] as Map<String, dynamic>;
//     final ratings = ratingsData.map(
//       (key, value) => MapEntry(key, value as int),
//     );

//     return EvaluationModel(
//       id: doc.id,
//       volunteerId: data['volunteerId'] ?? '',
//       volunteerName: data['volunteerName'] ?? '',
//       evaluatorName: data['evaluatorName'] ?? '',
//       month: data['month'] ?? '',
//       year: data['year'] ?? 0,
//       ratings: ratings,
//       totalScore: data['totalScore'] ?? 0,
//       averageScore: (data['averageScore'] ?? 0.0).toDouble(),
//       notes: data['notes'],
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'volunteerId': volunteerId,
//       'volunteerName': volunteerName,
//       'evaluatorName': evaluatorName,
//       'month': month,
//       'year': year,
//       'ratings': ratings,
//       'totalScore': totalScore,
//       'averageScore': averageScore,
//       'notes': notes,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.now(),
//     };
//   }

//   static EvaluationModel create({
//     required String volunteerId,
//     required String volunteerName,
//     required String evaluatorName,
//     required String month,
//     required int year,
//     required Map<String, int> ratings,
//     String? notes,
//   }) {
//     final totalScore = ratings.values.reduce((a, b) => a + b);
//     final averageScore = totalScore / ratings.length;

//     return EvaluationModel(
//       id: '',
//       volunteerId: volunteerId,
//       volunteerName: volunteerName,
//       evaluatorName: evaluatorName,
//       month: month,
//       year: year,
//       ratings: ratings,
//       totalScore: totalScore,
//       averageScore: averageScore,
//       notes: notes,
//       createdAt: DateTime.now(),
//     );
//   }
// }



// ============================================
// FILE: lib/data/models/evaluation_model.dart (UPDATED)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/evaluation.dart';

class EvaluationModel extends Evaluation {
  EvaluationModel({
    required super.id,
    required super.volunteerId,
    required super.volunteerName,
    required super.evaluatorName,
    required super.month,
    required super.year,
    required super.rating,
    super.notes,
    required super.createdAt,
  });

  factory EvaluationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EvaluationModel(
      id: doc.id,
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      evaluatorName: data['evaluatorName'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? 0,
      rating: data['rating'] ?? 0,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'evaluatorName': evaluatorName,
      'month': month,
      'year': year,
      'rating': rating,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }
}
