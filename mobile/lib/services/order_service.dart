import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/banner_model.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<(String, String)> placeOrder({
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
    // Pre-allocate the order ref so we can return its ID after the transaction.
    final orderRef = _db.collection(AppConstants.colOrders).doc();

    // Aggregate total quantity needed per product (multiple cart lines can
    // share the same productId when they differ only by size/color).
    final Map<String, int> neededQty = {};
    for (final item in items) {
      neededQty[item.productId] = (neededQty[item.productId] ?? 0) + item.quantity;
    }

    final productRefs = neededQty.keys
        .map((id) => _db.collection(AppConstants.colProducts).doc(id))
        .toList();

    final counterRef = _db.collection('counters').doc('orders');
    String generatedOrderNumber = '';

    await _db.runTransaction((tx) async {
      // ── Phase 1: reads (must all come before any writes) ────────────────
      final counterSnap = await tx.get(counterRef);
      final snaps = await Future.wait(productRefs.map((ref) => tx.get(ref)));

      // ── Phase 2: stock validation ────────────────────────────────────────
      for (int i = 0; i < productRefs.length; i++) {
        final snap = snaps[i];
        final productId = productRefs[i].id;
        final data = snap.data();
        final currentStock = (data?['stock'] as int?) ?? 0;
        final required = neededQty[productId]!;

        if (!snap.exists || currentStock < required) {
          final name = data?['name'] as String? ?? productId;
          throw Exception(
            '"$name" is no longer available in the requested quantity. '
            'Please update your cart and try again.',
          );
        }
      }

      // ── Phase 3: create order ────────────────────────────────────────────
      final count = ((counterSnap.data()?['count'] as int?) ?? 0) + 1;
      generatedOrderNumber = 'FS${count.toString().padLeft(4, '0')}';
      tx.set(counterRef, {'count': count}, SetOptions(merge: true));

      final now = FieldValue.serverTimestamp();
      tx.set(orderRef, {
        'userId': userId,
        'orderNumber': generatedOrderNumber,
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

      // ── Phase 4: decrement stock atomically ──────────────────────────────
      for (int i = 0; i < productRefs.length; i++) {
        final qty = neededQty[productRefs[i].id]!;
        tx.update(productRefs[i], {'stock': FieldValue.increment(-qty)});
      }
    });

    return (orderRef.id, generatedOrderNumber);
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
