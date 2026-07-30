// ============================================
// FILE: lib/presentation/providers/evaluation_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import '../../data/models/evaluation_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/volunteer_model.dart';
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

  Future<List<EvaluationModel>> getExistingEvaluationsForMonth(
    String month,
    String evaluationName,
  ) async {
    return _repository.getEvaluationsByMonthAndName(month, evaluationName);
  }

  Future<int> createBulkAttendanceEvaluations({
    required List<VolunteerModel> volunteers,
    required List<EventModel> qaflaEvents,
    required String month,
    required DateTime evaluationDate,
    required String evaluationName,
    required String evaluatorName,
  }) async {
    final existing = await getExistingEvaluationsForMonth(
      month,
      evaluationName,
    );
    final existingVolunteerIds = existing.map((e) => e.volunteerId).toSet();
    final monthEvents = qaflaEvents
        .where((event) => _matchesMonth(event, month))
        .toList();

    var createdCount = 0;
    for (final volunteer in volunteers) {
      if (existingVolunteerIds.contains(volunteer.id)) {
        continue;
      }

      final attendedCount = monthEvents
          .where((event) => event.volunteerIds.contains(volunteer.id))
          .length;
      final totalCount = monthEvents.length;
      final score = totalCount == 0
          ? 0
          : ((attendedCount / totalCount) * 10).clamp(0.0, 10.0);

      final evaluation = EvaluationModel(
        id: '',
        volunteerId: volunteer.id,
        volunteerName: volunteer.name,
        evaluationName: evaluationName,
        evaluatorName: evaluatorName,
        month: month,
        year: DateTime.parse('$month-01').year,
        rating: score.round(),
        notes: 'تم إنشاؤه تلقائيًا',
        createdAt: evaluationDate,
      );

      final createdId = await createEvaluation(evaluation);
      if (createdId != null) {
        createdCount++;
      }
    }

    return createdCount;
  }

  Future<int> createBulkDistributionEvaluations({
    required List<VolunteerModel> volunteers,
    required List<EventModel> qaflaEvents,
    required String month,
    required DateTime evaluationDate,
    required String evaluationName,
    required String evaluatorName,
  }) async {
    final existing = await getExistingEvaluationsForMonth(
      month,
      evaluationName,
    );
    final existingVolunteerIds = existing.map((e) => e.volunteerId).toSet();
    final monthEvents = qaflaEvents
        .where((event) => _matchesMonth(event, month))
        .toList();

    var createdCount = 0;
    for (final volunteer in volunteers) {
      if (existingVolunteerIds.contains(volunteer.id)) {
        continue;
      }

      final attendedEvents = monthEvents
          .where((event) => event.volunteerIds.contains(volunteer.id))
          .toList();
      final distributionCount = attendedEvents.where((event) {
        final distribution = event.qaflaDistribution[volunteer.id] ?? false;
        return distribution;
      }).length;
      final score = attendedEvents.isEmpty
          ? 0
          : ((distributionCount / attendedEvents.length) * 10).clamp(0.0, 10.0);

      final evaluation = EvaluationModel(
        id: '',
        volunteerId: volunteer.id,
        volunteerName: volunteer.name,
        evaluationName: evaluationName,
        evaluatorName: evaluatorName,
        month: month,
        year: DateTime.parse('$month-01').year,
        rating: score.round(),
        notes: 'تم إنشاؤه تلقائيًا',
        createdAt: evaluationDate,
      );

      final createdId = await createEvaluation(evaluation);
      if (createdId != null) {
        createdCount++;
      }
    }

    return createdCount;
  }

  bool _matchesMonth(EventModel event, String monthKey) {
    try {
      final eventDate = DateTime.parse(event.date);
      final monthDate = DateTime.parse('$monthKey-01');
      return eventDate.year == monthDate.year &&
          eventDate.month == monthDate.month;
    } catch (_) {
      return false;
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
