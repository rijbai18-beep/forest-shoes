import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? gender;
  final List<String> images;
  final double price;
  final double? salePrice;
  final List<String> colors;
  final List<String> sizes;
  final int stock;
  final bool hasEngraving;
  final double engravingFee;
  final int engravingMaxChars;
  final List<String> tags;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime createdAt;
  final Map<String, dynamic>? customFields;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.gender,
    required this.images,
    required this.price,
    this.salePrice,
    required this.colors,
    required this.sizes,
    required this.stock,
    this.hasEngraving = false,
    this.engravingFee = 100.0,
    this.engravingMaxChars = 10,
    this.tags = const [],
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
    this.customFields,
  });

  bool get isOnSale => salePrice != null && salePrice! < price;
  bool get inStock => stock > 0;
  double get effectivePrice => isOnSale ? salePrice! : price;
  double get discountPercentage =>
      isOnSale ? ((price - salePrice!) / price * 100).roundToDouble() : 0;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      gender: data['gender'],
      images: List<String>.from(data['images'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      salePrice: data['salePrice'] != null ? (data['salePrice']).toDouble() : null,
      colors: List<String>.from(data['colors'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      stock: data['stock'] ?? 0,
      hasEngraving: data['hasEngraving'] ?? false,
      engravingFee: (data['engravingFee'] ?? 100.0).toDouble(),
      engravingMaxChars: data['engravingMaxChars'] ?? 10,
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customFields: data['customFields'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'gender': gender,
        'images': images,
        'price': price,
        'salePrice': salePrice,
        'colors': colors,
        'sizes': sizes,
        'stock': stock,
        'hasEngraving': hasEngraving,
        'engravingFee': engravingFee,
        'engravingMaxChars': engravingMaxChars,
        'tags': tags,
        'isActive': isActive,
        'rating': rating,
        'reviewCount': reviewCount,
        'isFeatured': isFeatured,
        'createdAt': Timestamp.fromDate(createdAt),
        'customFields': customFields,
      };
}

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final List<Map<String, dynamic>> customFields;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isActive = true,
    this.customFields = const [],
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      customFields: List<Map<String, dynamic>>.from(data['customFields'] ?? []),
    );
  }
}

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
