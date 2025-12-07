// ============================================
// FILE: lib/presentation/providers/volunteer_provider.dart
// UPDATED: Added age and committee parameters
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

  // Get all volunteers stream
  Stream<List<VolunteerModel>> getVolunteers() {
    return _repository.getAllVolunteers();
  }

  // Create volunteer
  Future<String?> createVolunteer({
    required String name,
    required String phone,
    required String email,
    required String address,
    String? nationalId,
    int? age, // NEW
    String? committeeId, // NEW
    String? committeeName, // NEW
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
        age: age, // NEW
        committeeId: committeeId, // NEW
        committeeName: committeeName, // NEW
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

  // Update volunteer with map (easier for partial updates)
Future<bool> updateVolunteerData(
    String id,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final volunteer = await _repository.getVolunteerById(id);
      if (volunteer == null) {
        _error = 'Volunteer not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatedVolunteer = volunteer.copyWith(
        name: updates['name'],
        phone: updates['phone'],
        email: updates['email'],
        address: updates['address'],
        nationalId: updates['nationalId'],
        age: updates['age'],
        committeeId: updates['committeeId'],
        committeeName: updates['committeeName'],
        hasInterview: updates['hasInterview'],
        hasTshirt: updates['hasTshirt'], // ADD THIS
        birthDate: updates['birthDate'], // ADD THIS
        gender: updates['gender'], // ADD THIS
        educationalLevel: updates['educationalLevel'], // ADD THIS
        university: updates['university'], // ADD THIS
        profileImage: updates['profileImage'], // ADD THIS
      );

      final success = await _repository.updateVolunteer(id, updatedVolunteer);
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

  // Get volunteers by committee
  Future<List<VolunteerModel>> getVolunteersByCommittee(
    String committeeId,
  ) async {
    final allVolunteers = await _repository.getAllVolunteers().first;
    return allVolunteers.where((v) => v.committeeId == committeeId).toList();
  }
}
