import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/banner_model.dart';

class SupportService {
  final _db = FirebaseFirestore.instance;

  Future<String> createTicket({
    required String userId,
    required String userName,
    required String subject,
    required String firstMessage,
  }) async {
    final ticketRef = _db.collection(AppConstants.colSupportTickets).doc();
    final now = FieldValue.serverTimestamp();

    await ticketRef.set({
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'status': AppConstants.ticketOpen,
      'unreadCount': 0,
      'createdAt': now,
      'lastReply': now,
    });

    await ticketRef.collection(AppConstants.subMessages).add({
      'senderId': userId,
      'senderName': userName,
      'message': firstMessage,
      'isAdmin': false,
      'createdAt': now,
    });

    return ticketRef.id;
  }

  Future<List<SupportTicketModel>> getUserTickets(String userId) async {
    final snapshot = await _db
        .collection(AppConstants.colSupportTickets)
        .where('userId', isEqualTo: userId)
        .orderBy('lastReply', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SupportTicketModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<TicketMessageModel>> getMessages(String ticketId) {
    return _db
        .collection(AppConstants.colSupportTickets)
        .doc(ticketId)
        .collection(AppConstants.subMessages)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TicketMessageModel.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String message,
    bool isAdmin = false,
  }) async {
    final ticketRef =
        _db.collection(AppConstants.colSupportTickets).doc(ticketId);
    final now = FieldValue.serverTimestamp();

    await ticketRef.collection(AppConstants.subMessages).add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isAdmin': isAdmin,
      'createdAt': now,
    });

    await ticketRef.update({'lastReply': now});
  }

  Future<void> closeTicket(String ticketId) async {
    await _db
        .collection(AppConstants.colSupportTickets)
        .doc(ticketId)
        .update({'status': AppConstants.ticketClosed});
  }
}
