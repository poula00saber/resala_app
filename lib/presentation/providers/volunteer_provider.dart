// ============================================
// FILE: lib/presentation/providers/volunteer_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import '../../data/models/volunteer_model.dart';
import '../../data/repositories/volunteer_repository.dart';

class VolunteerProvider with ChangeNotifier {
  final VolunteerRepository _repository = VolunteerRepository();

  List<VolunteerModel> _volunteers = [];
  List<VolunteerModel> get volunteers => _volunteers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Initialize volunteers stream
  void initVolunteers() {
    _repository.getAllVolunteers().listen(
      (volunteers) {
        _volunteers = volunteers;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create volunteer
  Future<String?> createVolunteer({
    required String name,
    required String phone,
    required String email,
    required String address,
    String? nationalId,
    bool hasInterview = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final volunteer = VolunteerModel(
        id: '',
        name: name,
        phone: phone,
        email: email,
        address: address,
        nationalId: nationalId,
        hasInterview: hasInterview,
        createdAt: DateTime.now(),
      );

      final id = await _repository.createVolunteer(volunteer);
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

  // Update volunteer
  Future<bool> updateVolunteer(String id, VolunteerModel volunteer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateVolunteer(id, volunteer);
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

  // Delete volunteer
  Future<bool> deleteVolunteer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteVolunteer(id);
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

  // Get volunteer by ID
  Future<VolunteerModel?> getVolunteerById(String id) async {
    return await _repository.getVolunteerById(id);
  }

  // Get volunteers by IDs
  Future<List<VolunteerModel>> getVolunteersByIds(List<String> ids) async {
    return await _repository.getVolunteersByIds(ids);
  }

  // Search volunteers
  Stream<List<VolunteerModel>> searchVolunteers(String query) {
    return _repository.searchVolunteers(query);
  }
}
