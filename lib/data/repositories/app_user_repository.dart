// ============================================
// FILE: lib/data/repositories/app_user_repository.dart
// Repository for application user management
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';

class AppUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'app_users';

  // Get all users
  Stream<List<AppUserModel>> getAllUsers() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUserModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get user by ID
  Future<AppUserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return AppUserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get user by email
  Future<AppUserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AppUserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Create new user (admin only)
  Future<String?> createUser({
    required String email,
    required String password,
    String? displayName,
    bool isAdmin = false,
    required List<PagePermission> permissions,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      final user = AppUserModel(
        id: userId,
        email: email,
        displayName: displayName,
        isAdmin: isAdmin,
        permissions: permissions,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(user.toFirestore());

      // Sign out the newly created user (so admin stays logged in)
      // Note: This will sign out the current user too, so we need to handle this differently
      // The admin should use a secondary Firebase app instance for user creation

      return userId;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Create user document only (when auth user already exists)
  Future<bool> createUserDocument(AppUserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .set(user.toFirestore());
      return true;
    } catch (e) {
      print('Error creating user document: $e');
      return false;
    }
  }

  // Update user permissions
  Future<bool> updateUserPermissions(
    String userId,
    List<PagePermission> permissions,
  ) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'permissions': permissions.map((p) => p.toMap()).toList(),
      });
      return true;
    } catch (e) {
      print('Error updating permissions: $e');
      return false;
    }
  }

  // Update user admin status
  Future<bool> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isAdmin': isAdmin,
      });
      return true;
    } catch (e) {
      print('Error updating admin status: $e');
      return false;
    }
  }

  // Update last login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'lastLogin': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_collection).doc(userId).delete();

      // Note: Deleting Firebase Auth user requires admin SDK or the user to be signed in
      // For now, we only delete the Firestore document

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get current logged in user
  Future<AppUserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return await getUserById(firebaseUser.uid);
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  // Sign in user
  Future<AppUserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Get or create user document
      var user = await getUserById(userId);

      if (user == null) {
        // Create user document if it doesn't exist (for first admin)
        user = AppUserModel(
          id: userId,
          email: email,
          isAdmin: true, // First user is admin
          permissions: AppPages.getAllPagesDefault()
              .map((p) => p.copyWith(canAccess: true, canAddDelete: true))
              .toList(),
          createdAt: DateTime.now(),
        );
        await createUserDocument(user);
      }

      // Update last login
      await updateLastLogin(userId);

      return user;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
