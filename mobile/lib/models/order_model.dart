import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class AddressModel {
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String postcode;
  final String country;

  const AddressModel({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.postcode,
    this.country = 'Mauritius',
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) => AddressModel(
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        line1: map['line1'] ?? '',
        line2: map['line2'],
        city: map['city'] ?? '',
        postcode: map['postcode'] ?? '',
        country: map['country'] ?? 'Mauritius',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'postcode': postcode,
        'country': country,
      };

  String get formatted => '$line1${line2 != null ? ', $line2' : ''}, $city, $postcode, $country';
}

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double engravingFee;
  final double couponDiscount;
  final double total;
  final String paymentType;
  final String paymentTypeId;
  final String deliveryType;
  final String deliveryTypeId;
  final String status;
  final AddressModel address;
  final String? note;
  final String? couponCode;
  final String? couponId;
  final bool isPostage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? paymentProof;
  final String? orderNumber;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.engravingFee,
    required this.couponDiscount,
    required this.total,
    required this.paymentType,
    required this.paymentTypeId,
    required this.deliveryType,
    required this.deliveryTypeId,
    required this.status,
    required this.address,
    this.note,
    this.couponCode,
    this.couponId,
    this.isPostage = false,
    required this.createdAt,
    required this.updatedAt,
    this.paymentProof,
    this.orderNumber,
  });

  String get displayId => orderNumber ?? '#${id.substring(0, 8).toUpperCase()}';

  String get statusLabel {
    const labels = {
      'new': 'New',
      'pending_payment': 'Pending Payment',
      'reviewed': 'Payment Reviewed',
      'processing': 'Processing',
      'dispatched': 'Dispatched',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      engravingFee: (data['engravingFee'] ?? 0).toDouble(),
      couponDiscount: (data['couponDiscount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentType: data['paymentType'] ?? '',
      paymentTypeId: data['paymentTypeId'] ?? '',
      deliveryType: data['deliveryType'] ?? '',
      deliveryTypeId: data['deliveryTypeId'] ?? '',
      status: data['status'] ?? 'new',
      address: AddressModel.fromMap(
          Map<String, dynamic>.from(data['address'] ?? {})),
      note: data['note'],
      couponCode: data['couponCode'],
      couponId: data['couponId'],
      isPostage: data['isPostage'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentProof: data['paymentProof'],
      orderNumber: data['orderNumber'],
    );
  }

  Map<String, dynamic> toMap() => {
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
        'status': status,
        'address': address.toMap(),
        'note': note,
        'couponCode': couponCode,
        'couponId': couponId,
        'isPostage': isPostage,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'paymentProof': paymentProof,
      };
}
