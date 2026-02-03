// ============================================
// FILE: lib/services/auth_service.dart
// Service for managing authentication and user state
// ============================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Try to get existing user document
      _currentUser = await _userRepository.getUserById(firebaseUser.uid);

      // If user document doesn't exist, create it
      if (_currentUser == null) {
        await _createUserDocument(firebaseUser);
        _currentUser = await _userRepository.getUserById(firebaseUser.uid);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create user document for Firebase Auth user
  Future<void> _createUserDocument(User firebaseUser) async {
    // Check if this is an admin email (you can customize this list)
    final adminEmails = [
      'admin.resala@gmail.com',
      'admin@resala.org',
      'admin@resala.com',
    ];

    final isAdminEmail = adminEmails.contains(
      firebaseUser.email?.toLowerCase(),
    );

    final newUser = AppUserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isAdmin: isAdminEmail, // Set as admin if email is in admin list
      permissions: isAdminEmail ? [] : AppPages.getAllPagesDefault(),
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('app_users')
        .doc(firebaseUser.uid)
        .set(newUser.toFirestore());
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
    if (isAdmin) return true;
    return _currentUser?.canAccessPage(pageId) ?? false;
  }

  // Check if user can add/delete on a page
  bool canAddDeleteOnPage(String pageId) {
    if (isAdmin) return true;
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
