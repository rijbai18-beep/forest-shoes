import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/banner_model.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<String> placeOrder({
    required String userId,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double engravingFee,
    required double couponDiscount,
    required double total,
    required String paymentType,
    required String paymentTypeId,
    required String deliveryType,
    required String deliveryTypeId,
    required AddressModel address,
    String? note,
    String? couponCode,
    String? couponId,
    bool isPostage = false,
  }) async {
    final orderRef = _db.collection(AppConstants.colOrders).doc();
    final now = FieldValue.serverTimestamp();

    await orderRef.set({
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'engravingFee': engravingFee,
      'couponDiscount': couponDiscount,
      'total': total,
      'paymentType': paymentType,
      'paymentTypeId': paymentTypeId,
      'deliveryType': deliveryType,
      'deliveryTypeId': deliveryTypeId,
      'status': AppConstants.statusNew,
      'address': address.toMap(),
      'note': note,
      'couponCode': couponCode,
      'couponId': couponId,
      'isPostage': isPostage,
      'createdAt': now,
      'updatedAt': now,
    });

    return orderRef.id;
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    final snapshot = await _db
        .collection(AppConstants.colOrders)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection(AppConstants.colOrders).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  Stream<OrderModel?> orderStream(String orderId) {
    return _db
        .collection(AppConstants.colOrders)
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  Future<List<BannerModel>> getBanners() async {
    final snapshot = await _db
        .collection(AppConstants.colBanners)
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .get();
    return snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();
  }

  Future<List<PaymentTypeModel>> getPaymentTypes() async {
    final snapshot = await _db
        .collection(AppConstants.colPaymentTypes)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => PaymentTypeModel.fromFirestore(doc)).toList();
  }

  Future<List<DeliveryTypeModel>> getDeliveryTypes() async {
    final snapshot = await _db
        .collection(AppConstants.colDeliveryTypes)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => DeliveryTypeModel.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> getSettings() async {
    final doc = await _db
        .collection(AppConstants.colSettings)
        .doc(AppConstants.settingsGlobal)
        .get();
    return doc.exists ? doc.data() ?? {} : {};
  }

  Future<Map<String, dynamic>> getContent(String type) async {
    final doc = await _db.collection(AppConstants.colContent).doc(type).get();
    return doc.exists ? doc.data() ?? {} : {};
  }
}
