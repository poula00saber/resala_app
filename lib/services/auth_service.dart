// ============================================
// FILE: lib/services/auth_service.dart
// Service for managing authentication and user state
// ============================================

import 'package:flutter/foundation.dart';
import '../data/models/app_user_model.dart';
import '../data/repositories/app_user_repository.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AppUserRepository _userRepository = AppUserRepository();

  AppUserModel? _currentUser;
  bool _isLoading = false;

  AppUserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _userRepository.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _userRepository.signIn(email, password);

    _isLoading = false;
    notifyListeners();

    return _currentUser != null;
  }

  // Sign out
  Future<void> signOut() async {
    await _userRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Refresh current user data
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      _currentUser = await _userRepository.getUserById(_currentUser!.id);
      notifyListeners();
    }
  }

  // Check if user can access a page
  bool canAccessPage(String pageId) {
    return _currentUser?.canAccessPage(pageId) ?? false;
  }

  // Check if user can add/delete on a page
  bool canAddDeleteOnPage(String pageId) {
    return _currentUser?.canAddDeleteOnPage(pageId) ?? false;
  }

  // Set current user (for testing or manual setting)
  void setCurrentUser(AppUserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Set admin user for testing (auto-login as admin)
  void setAdminForTesting() {
    _currentUser = AppUserModel(
      id: 'admin_test',
      email: 'admin@resala.com',
      isAdmin: true,
      permissions: [], // Admin has all access by default
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }
}
