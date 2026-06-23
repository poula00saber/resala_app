import 'package:cloud_firestore/cloud_firestore.dart';

class OperationLogModel {
  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String? entityName;
  final String? userId;
  final String? userEmail;
  final DateTime? createdAt;
  final Map<String, dynamic>? details;

  OperationLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.entityName,
    this.userId,
    this.userEmail,
    this.createdAt,
    this.details,
  });

  factory OperationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OperationLogModel(
      id: doc.id,
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      entityName: data['entityName'],
      userId: data['userId'],
      userEmail: data['userEmail'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      details: (data['details'] as Map<String, dynamic>?),
    );
  }
}
