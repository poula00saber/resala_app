// ============================================
// FILE: lib/presentation/providers/evaluation_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import '../../data/models/evaluation_model.dart';
import '../../data/repositories/evaluation_repository.dart';

class EvaluationProvider with ChangeNotifier {
  final EvaluationRepository _repository = EvaluationRepository();

  List<EvaluationModel> _evaluations = [];
  List<EvaluationModel> get evaluations => _evaluations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Get evaluations for a volunteer
  Stream<List<EvaluationModel>> getEvaluationsForVolunteer(String volunteerId) {
    return _repository.getEvaluationsForVolunteer(volunteerId);
  }

  // Get all evaluations
  Stream<List<EvaluationModel>> getAllEvaluations() {
    return _repository.getAllEvaluations();
  }

  // Create evaluation
  Future<String?> createEvaluation(EvaluationModel evaluation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.createEvaluation(evaluation);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update evaluation
  Future<bool> updateEvaluation(String id, EvaluationModel evaluation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateEvaluation(id, evaluation);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete evaluation
  Future<bool> deleteEvaluation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteEvaluation(id);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get average rating
  Future<double> getAverageRating(String volunteerId) async {
    return await _repository.getAverageRating(volunteerId);
  }

  // Get latest evaluation
  Future<EvaluationModel?> getLatestEvaluation(String volunteerId) async {
    return await _repository.getLatestEvaluation(volunteerId);
  }
}
