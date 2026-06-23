import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operation_log_model.dart';
import '../../core/constants/firebase_constants.dart';

class OperationLogPage {
  final List<OperationLogModel> logs;
  final DocumentSnapshot? lastDoc;

  OperationLogPage({required this.logs, required this.lastDoc});
}

class OperationLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OperationLogPage> getLogs({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(FirebaseConstants.operationLogsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final logs = snapshot.docs
        .map((doc) => OperationLogModel.fromFirestore(doc))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return OperationLogPage(logs: logs, lastDoc: lastDoc);
  }
}
