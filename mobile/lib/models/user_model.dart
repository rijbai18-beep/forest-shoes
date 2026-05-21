import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final List<AddressModel> addresses;
  final bool isActive;
  final bool isAdmin;
  final List<String> fcmTokens;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.addresses = const [],
    this.isActive = true,
    this.isAdmin = false,
    this.fcmTokens = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      addresses: (data['addresses'] as List<dynamic>? ?? [])
          .map((e) => AddressModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      isActive: data['isActive'] ?? true,
      isAdmin: data['isAdmin'] ?? false,
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'isActive': isActive,
        'isAdmin': isAdmin,
        'fcmTokens': fcmTokens,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    List<AddressModel>? addresses,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        addresses: addresses ?? this.addresses,
        isActive: isActive,
        isAdmin: isAdmin,
        fcmTokens: fcmTokens,
        createdAt: createdAt,
      );
}
