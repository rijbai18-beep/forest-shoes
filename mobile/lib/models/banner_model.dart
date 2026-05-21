import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? link;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.link,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      link: data['link'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'],
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: d['type'] ?? 'general',
      data: d['data'] != null ? Map<String, dynamic>.from(d['data']) : null,
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CouponModel {
  final String id;
  final String code;
  final String type; // 'percentage' | 'amount'
  final double value;
  final double? minOrder;
  final double? maxDiscount;
  final int? maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrder,
    this.maxDiscount,
    this.maxUses,
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      type: data['type'] ?? 'amount',
      value: (data['value'] ?? 0).toDouble(),
      minOrder: data['minOrder'] != null ? (data['minOrder']).toDouble() : null,
      maxDiscount:
          data['maxDiscount'] != null ? (data['maxDiscount']).toDouble() : null,
      maxUses: data['maxUses'],
      usedCount: data['usedCount'] ?? 0,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class PaymentTypeModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final double fee;
  final String? instructions;
  final bool isActive;

  const PaymentTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.fee = 0.0,
    this.instructions,
    this.isActive = true,
  });

  factory PaymentTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTypeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      icon: data['icon'],
      fee: (data['fee'] ?? 0).toDouble(),
      instructions: data['instructions'],
      isActive: data['isActive'] ?? true,
    );
  }
}

class DeliveryTypeModel {
  final String id;
  final String name;
  final String? description;
  final double fee;
  final String? estimatedDays;
  final bool isActive;

  const DeliveryTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.fee = 0.0,
    this.estimatedDays,
    this.isActive = true,
  });

  factory DeliveryTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryTypeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      fee: (data['fee'] ?? 0).toDouble(),
      estimatedDays: data['estimatedDays'],
      isActive: data['isActive'] ?? true,
    );
  }
}

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String status;
  final DateTime createdAt;
  final DateTime lastReply;
  final int unreadCount;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastReply,
    this.unreadCount = 0,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      subject: data['subject'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReply: (data['lastReply'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}

class TicketMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;

  const TicketMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
  });

  factory TicketMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TicketMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
