// ============================================
// FILE: lib/presentation/providers/committee_provider.dart
// UPDATED: Better error handling
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

  // Initialize committees stream
  void initCommittees() {
    print('🔄 CommitteeProvider: Initializing committees...');
    _repository.getAllCommittees().listen(
      (committees) {
        print('✅ CommitteeProvider: Loaded ${committees.length} committees');
        _committees = committees;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        print('❌ CommitteeProvider Error: $error');
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get active committees stream
  Stream<List<CommitteeModel>> getActiveCommittees() {
    print('🔄 CommitteeProvider: getActiveCommittees() called');
    return _repository.getActiveCommittees().handleError((error) {
      print('❌ CommitteeProvider.getActiveCommittees() error: $error');
      throw error;
    });
  }

  // Get all committees stream
  Stream<List<CommitteeModel>> getAllCommittees() {
    print('🔄 CommitteeProvider: getAllCommittees() called');
    return _repository.getAllCommittees().handleError((error) {
      print('❌ CommitteeProvider.getAllCommittees() error: $error');
      throw error;
    });
  }

  // Create committee
  Future<String?> createCommittee({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔄 CommitteeProvider: Creating committee: $name');

    try {
      final committee = CommitteeModel(
        id: '',
        name: name,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = await _repository.createCommittee(committee);

      if (id != null) {
        print('✅ CommitteeProvider: Committee created with ID: $id');
      } else {
        print('❌ CommitteeProvider: Failed to create committee');
        _error = 'Failed to create committee';
      }

      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      print('❌ CommitteeProvider.createCommittee() ERROR: $e');
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

    print('🔄 CommitteeProvider: Updating committee $id: ${committee.name}');

    try {
      final success = await _repository.updateCommittee(id, committee);

      if (success) {
        print('✅ CommitteeProvider: Committee $id updated successfully');
        // Update local list
        final index = _committees.indexWhere((c) => c.id == id);
        if (index != -1) {
          _committees[index] = committee.copyWith(id: id);
        }
      } else {
        print('❌ CommitteeProvider: Failed to update committee $id');
        _error = 'Failed to update committee';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('❌ CommitteeProvider.updateCommittee() ERROR: $e');
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

    print('🔄 CommitteeProvider: Deleting committee $id');

    try {
      final success = await _repository.deleteCommittee(id);

      if (success) {
        print('✅ CommitteeProvider: Committee $id deleted successfully');
        // Remove from local list
        _committees.removeWhere((c) => c.id == id);
      } else {
        print('❌ CommitteeProvider: Failed to delete committee $id');
        _error = 'Failed to delete committee';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('❌ CommitteeProvider.deleteCommittee() ERROR: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle committee status
  Future<bool> toggleCommitteeStatus(String id, bool isActive) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔄 CommitteeProvider: Toggling committee $id to $isActive');

    try {
      final success = await _repository.toggleCommitteeStatus(id, isActive);

      if (success) {
        print('✅ CommitteeProvider: Committee $id status toggled to $isActive');
        // Update local list
        final index = _committees.indexWhere((c) => c.id == id);
        if (index != -1) {
          _committees[index] = _committees[index].copyWith(isActive: isActive);
        }
      } else {
        print('❌ CommitteeProvider: Failed to toggle committee $id status');
        _error = 'Failed to toggle committee status';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('❌ CommitteeProvider.toggleCommitteeStatus() ERROR: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get committee by ID
  Future<CommitteeModel?> getCommitteeById(String id) async {
    print('🔄 CommitteeProvider: Getting committee $id');
    try {
      final committee = await _repository.getCommitteeById(id);
      if (committee != null) {
        print('✅ CommitteeProvider: Found committee $id');
      } else {
        print('❌ CommitteeProvider: Committee $id not found');
      }
      return committee;
    } catch (e) {
      print('❌ CommitteeProvider.getCommitteeById() ERROR: $e');
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
