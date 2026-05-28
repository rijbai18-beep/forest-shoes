import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/constants.dart';

/// Fire-and-forget audit logger. All writes fail silently so the app
/// never crashes because of logging.
class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void logAction(String action, {Map<String, dynamic>? details}) {
    final user = _auth.currentUser;
    _db.collection(AppConstants.colAuditLogs).add({
      'type': 'action',
      'platform': 'mobile',
      'userId': user?.uid,
      'userEmail': user?.email,
      'action': action,
      'details': details,
      'errorMessage': null,
      'stackTrace': null,
      'timestamp': FieldValue.serverTimestamp(),
    }).then<void>((_) {}).catchError((_) {});
  }

  void logError(Object error, StackTrace? stackTrace, {String context = 'uncaught_error', Map<String, dynamic>? details}) {
    final user = _auth.currentUser;
    _db.collection(AppConstants.colAuditLogs).add({
      'type': 'error',
      'platform': 'mobile',
      'userId': user?.uid,
      'userEmail': user?.email,
      'action': context,
      'details': details,
      'errorMessage': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    }).then<void>((_) {}).catchError((_) {});
  }
}
