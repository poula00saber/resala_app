// ============================================
// FILE: lib/presentation/providers/interview_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import 'package:resala/data/models/interview_model.dart';
import 'package:resala/data/repositories/interview_repository.dart';
import 'package:resala/core/constants/firebase_constants.dart';

class InterviewProvider with ChangeNotifier {
  final InterviewRepository _repository = InterviewRepository();

  List<InterviewModel> _interviews = [];
  List<InterviewModel> get interviews => _interviews;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _filterStatus = 'pending'; // pending, completed, passed, failed, all
  String get filterStatus => _filterStatus;

  // Initialize interviews stream
  void initInterviews() {
    _repository.getAllInterviews().listen(
      (interviews) {
        _interviews = interviews;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get all interviews stream
  Stream<List<InterviewModel>> getInterviews() {
    return _repository.getAllInterviews();
  }

  // Set filter status
  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Get filtered interviews
  List<InterviewModel> get filteredInterviews {
    if (_filterStatus == 'all') return _interviews;
    return _interviews
        .where((interview) => interview.status == _filterStatus)
        .toList();
  }

  // Get interviews by status
  Stream<List<InterviewModel>> getInterviewsByStatus(String status) {
    return _repository.getInterviewsByStatus(status);
  }

  // Create interview
  Future<String?> createInterview({
    required String volunteerId,
    required String volunteerName,
    required DateTime interviewDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final interview = InterviewModel(
        id: '',
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        interviewDate: interviewDate,
        answers: {},
        status: FirebaseConstants.interviewStatusPending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _repository.createInterview(interview);
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

  // Update interview answers
  Future<bool> updateInterviewAnswers({
    required String interviewId,
    required Map<String, String> answers,
    bool? passed,
    int? totalGrade,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateInterviewAnswers(
        interviewId: interviewId,
        answers: answers,
        passed: passed,
        totalGrade: totalGrade,
        notes: notes,
      );

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

  // Get interview by ID
  Future<InterviewModel?> getInterviewById(String id) async {
    return await _repository.getInterviewById(id);
  }

  // Get interviews by volunteer ID
  Future<List<InterviewModel>> getInterviewsByVolunteerId(
    String volunteerId,
  ) async {
    return await _repository.getInterviewsByVolunteerId(volunteerId);
  }

  // Delete interview
  Future<bool> deleteInterview(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteInterview(id);
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

  // Search interviews
  Stream<List<InterviewModel>> searchInterviews(String query) {
    return _repository.searchInterviews(query);
  }

  // Get volunteers without interviews
  Future<List<dynamic>> getVolunteersWithoutInterviews(
    List<dynamic> allVolunteers,
  ) async {
    return await _repository.getVolunteersWithoutInterviews(allVolunteers);
  }
}
