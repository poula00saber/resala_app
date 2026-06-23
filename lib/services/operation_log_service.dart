import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firebase_constants.dart';

class OperationLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> log({
    required String action,
    required String entityType,
    required String entityId,
    String? entityName,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore
          .collection(FirebaseConstants.operationLogsCollection)
          .add({
            'action': action,
            'entityType': entityType,
            'entityId': entityId,
            'entityName': entityName,
            'details': details,
            'userId': user?.uid,
            'userEmail': user?.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Logging should never break app flow
      // ignore: avoid_print
      print('Error logging operation: $e');
    }
  }
}
