// ============================================
// FILE: lib/presentation/providers/volunteer_provider.dart
// UPDATED: Age is required in createVolunteer method
// ============================================

import 'package:flutter/foundation.dart';
import 'package:resala/core/constants/firebase_constants.dart';
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
        _volunteers.sort(
          (a, b) => FirebaseConstants.compareByDegreeAndName(
            a.educationalLevel ?? '',
            a.name,
            b.educationalLevel ?? '',
            b.name,
          ),
        );
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
    return _repository.getAllVolunteers().map((volunteers) {
      volunteers.sort(
        (a, b) => FirebaseConstants.compareByDegreeAndName(
          a.educationalLevel ?? '',
          a.name,
          b.educationalLevel ?? '',
          b.name,
        ),
      );
      return volunteers;
    });
  }

  // Create volunteer - UPDATED: age is now required
  Future<String?> createVolunteer({
    required String name,
    required String phone,
    required String email,
    required String address,
    String? nationalId,
    required int age, // CHANGED: Now required
    String? birthDate,
    String? gender,
    String? committeeId,
    String? committeeName,
    bool hasInterview = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate age - allow any age from 1 to 100
      if (age < 1 || age > 100) {
        throw Exception('العمر يجب أن يكون بين 1 و 100 سنة');
      }

      final volunteer = VolunteerModel(
        id: '',
        name: name,
        phone: phone,
        email: email,
        address: address,
        nationalId: nationalId,
        age: age,
        birthDate: birthDate,
        gender: gender,
        committeeId: committeeId,
        committeeName: committeeName,
        hasInterview: false,
        // Automatically determine educational level based on age
        educationalLevel: FirebaseConstants.getInitialEducationalLevel(age),
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

  // Add volunteer with full model
  Future<String?> addVolunteer(VolunteerModel volunteer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate age if present
      if (volunteer.age != null &&
          (volunteer.age! < 1 || volunteer.age! > 100)) {
        throw Exception('العمر يجب أن يكون بين 1 و 100 سنة');
      }

      // Auto-set educational level based on age if not provided
      final volunteerToCreate =
          volunteer.educationalLevel == null && volunteer.age != null
          ? volunteer.copyWith(
              educationalLevel: FirebaseConstants.getInitialEducationalLevel(
                volunteer.age!,
              ),
            )
          : volunteer;

      final id = await _repository.createVolunteer(volunteerToCreate);
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

  // Add this method to VolunteerProvider class:
  Future<bool> updateVolunteerInterviewStatus(
    String volunteerId,
    bool hasInterview,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await updateVolunteerData(volunteerId, {
        'hasInterview': hasInterview,
      });

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

  // Update volunteer level
  Future<bool> updateVolunteerLevel(String volunteerId, String newLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await updateVolunteerData(volunteerId, {
        'educationalLevel': newLevel,
      });

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

      // Validate age if being updated
      if (updates['age'] != null) {
        final newAge = updates['age'];
        if (newAge is int && (newAge < 1 || newAge > 100)) {
          _error = 'العمر يجب أن يكون بين 1 و 100 سنة';
          _isLoading = false;
          notifyListeners();
          return false;
        }
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
        hasTshirt: updates['hasTshirt'],
        birthDate: updates['birthDate'],
        gender: updates['gender'],
        educationalLevel:
            updates['educationalLevel'] ?? volunteer.educationalLevel,
        university: updates['university'],
        profileImage: updates['profileImage'],
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
    final volunteers = await _repository.getVolunteersByIds(ids);
    volunteers.sort(
      (a, b) => FirebaseConstants.compareByDegreeAndName(
        a.educationalLevel ?? '',
        a.name,
        b.educationalLevel ?? '',
        b.name,
      ),
    );
    return volunteers;
  }

  // Search volunteers (sorted by degree then name)
  Stream<List<VolunteerModel>> searchVolunteers(String query) {
    return _repository.searchVolunteers(query).map((volunteers) {
      volunteers.sort(
        (a, b) => FirebaseConstants.compareByDegreeAndName(
          a.educationalLevel ?? '',
          a.name,
          b.educationalLevel ?? '',
          b.name,
        ),
      );
      return volunteers;
    });
  }

  // Get volunteers by committee
  Future<List<VolunteerModel>> getVolunteersByCommittee(
    String committeeId,
  ) async {
    final allVolunteers = await _repository.getAllVolunteers().first;
    final filtered = allVolunteers
        .where((v) => v.committeeId == committeeId)
        .toList();
    filtered.sort(
      (a, b) => FirebaseConstants.compareByDegreeAndName(
        a.educationalLevel ?? '',
        a.name,
        b.educationalLevel ?? '',
        b.name,
      ),
    );
    return filtered;
  }

  // Get volunteers by educational level
  Future<List<VolunteerModel>> getVolunteersByLevel(String level) async {
    final allVolunteers = await _repository.getAllVolunteers().first;
    final filtered = allVolunteers
        .where((v) => v.educationalLevel == level)
        .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  // Get volunteers under 17 years old (شبل)
  Future<List<VolunteerModel>> getScoutVolunteers() async {
    final allVolunteers = await _repository.getAllVolunteers().first;
    return allVolunteers.where((v) => v.age != null && v.age! < 17).toList();
  }

  // Get volunteers 17 or older (جدد)
  Future<List<VolunteerModel>> getNewVolunteers() async {
    final allVolunteers = await _repository.getAllVolunteers().first;
    return allVolunteers.where((v) => v.age != null && v.age! >= 17).toList();
  }
}
