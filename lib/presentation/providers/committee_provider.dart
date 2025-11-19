// ============================================
// FILE 2: lib/presentation/providers/committee_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import '../../data/models/committee_model.dart';
import '../../data/repositories/committee_repository.dart';

class CommitteeProvider with ChangeNotifier {
  final CommitteeRepository _repository = CommitteeRepository();

  List<CommitteeModel> _committees = [];
  List<CommitteeModel> get committees => _committees;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Initialize committees
  void initCommittees() {
    _repository.getAllCommittees().listen(
      (committees) {
        _committees = committees;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get all committees
  Stream<List<CommitteeModel>> getAllCommittees() {
    return _repository.getAllCommittees();
  }

  // Get active committees
  Stream<List<CommitteeModel>> getActiveCommittees() {
    return _repository.getActiveCommittees();
  }

  // Create committee
  Future<String?> createCommittee({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final committee = CommitteeModel(
        id: '',
        name: name,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = await _repository.createCommittee(committee);
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

  // Update committee
  Future<bool> updateCommittee(String id, CommitteeModel committee) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateCommittee(id, committee);
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

  // Delete committee
  Future<bool> deleteCommittee(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteCommittee(id);
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
}
