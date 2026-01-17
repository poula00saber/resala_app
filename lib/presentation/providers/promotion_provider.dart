// ============================================
// FILE: lib/presentation/providers/promotion_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import 'package:resala/data/models/promotion_model.dart';
import 'package:resala/data/repositories/promotion_repository.dart';

class PromotionProvider with ChangeNotifier {
  final PromotionRepository _repository = PromotionRepository();

  PromotionRequirement? _currentPromotionRequirement;
  PromotionRequirement? get currentPromotionRequirement =>
      _currentPromotionRequirement;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Load promotion requirements for a volunteer
  Future<void> loadPromotionRequirements({
    required String volunteerId,
    required String currentLevel,
    required String nextLevel,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPromotionRequirement = await _repository.getPromotionRequirements(
        volunteerId,
        currentLevel,
        nextLevel,
      );
    } catch (e) {
      _error = e.toString();
      _currentPromotionRequirement = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle requirement status
  Future<bool> toggleRequirementStatus({
    required String requirementId,
    required bool isCompleted,
  }) async {
    if (_currentPromotionRequirement == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.updateRequirementStatus(
        _currentPromotionRequirement!.id,
        requirementId,
        isCompleted,
      );

      if (success) {
        // Reload requirements to get updated data
        await loadPromotionRequirements(
          volunteerId: _currentPromotionRequirement!.volunteerId,
          currentLevel: _currentPromotionRequirement!.currentLevel,
          nextLevel: _currentPromotionRequirement!.nextLevel,
        );
      }

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

  // Delete promotion requirements (after promotion)
  Future<bool> deleteCurrentPromotionRequirements() async {
    if (_currentPromotionRequirement == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deletePromotionRequirements(
        _currentPromotionRequirement!.id,
      );

      if (success) {
        _currentPromotionRequirement = null;
      }

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

  // Clear current requirements
  void clearRequirements() {
    _currentPromotionRequirement = null;
    notifyListeners();
  }
}
