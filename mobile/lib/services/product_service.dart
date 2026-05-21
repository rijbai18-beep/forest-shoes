import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/product_model.dart';

enum SortOption { newest, priceLow, priceHigh, rating, popular }

class ProductFilter {
  final String? category;
  final String? gender;
  final String? color;
  final String? size;
  final double? minPrice;
  final double? maxPrice;
  final bool? onSaleOnly;
  final bool? inStockOnly;
  final SortOption sort;

  const ProductFilter({
    this.category,
    this.gender,
    this.color,
    this.size,
    this.minPrice,
    this.maxPrice,
    this.onSaleOnly,
    this.inStockOnly,
    this.sort = SortOption.newest,
  });

  ProductFilter copyWith({
    String? category,
    String? gender,
    String? color,
    String? size,
    double? minPrice,
    double? maxPrice,
    bool? onSaleOnly,
    bool? inStockOnly,
    SortOption? sort,
  }) =>
      ProductFilter(
        category: category ?? this.category,
        gender: gender ?? this.gender,
        color: color ?? this.color,
        size: size ?? this.size,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        onSaleOnly: onSaleOnly ?? this.onSaleOnly,
        inStockOnly: inStockOnly ?? this.inStockOnly,
        sort: sort ?? this.sort,
      );
}

class ProductService {
  final _db = FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _buildQuery(ProductFilter filter) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.colProducts)
        .where('isActive', isEqualTo: true);

    if (filter.category != null && filter.category!.isNotEmpty) {
      query = query.where('category', isEqualTo: filter.category);
    }
    if (filter.gender != null && filter.gender!.isNotEmpty) {
      query = query.where('gender', isEqualTo: filter.gender);
    }

    switch (filter.sort) {
      case SortOption.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SortOption.priceLow:
        query = query.orderBy('price', descending: false);
        break;
      case SortOption.priceHigh:
        query = query.orderBy('price', descending: true);
        break;
      case SortOption.rating:
        query = query.orderBy('rating', descending: true);
        break;
      case SortOption.popular:
        query = query.orderBy('reviewCount', descending: true);
        break;
    }

    return query;
  }

  Future<(List<ProductModel>, DocumentSnapshot?)> getProducts(
      ProductFilter filter,
      {DocumentSnapshot? startAfter}) async {
    var query = _buildQuery(filter).limit(AppConstants.pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    var products =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

    // Client-side filters that Firestore can't compound
    if (filter.color != null && filter.color!.isNotEmpty) {
      products = products.where((p) => p.colors.contains(filter.color)).toList();
    }
    if (filter.size != null && filter.size!.isNotEmpty) {
      products = products.where((p) => p.sizes.contains(filter.size)).toList();
    }
    if (filter.minPrice != null) {
      products = products.where((p) => p.effectivePrice >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      products = products.where((p) => p.effectivePrice <= filter.maxPrice!).toList();
    }
    if (filter.onSaleOnly == true) {
      products = products.where((p) => p.isOnSale).toList();
    }
    if (filter.inStockOnly == true) {
      products = products.where((p) => p.inStock).toList();
    }

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (products, lastDoc);
  }

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _db.collection(AppConstants.colProducts).doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final snapshot = await _db
        .collection(AppConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.homeFeaturedLimit)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<List<ProductModel>> getSaleProducts() async {
    final snapshot = await _db
        .collection(AppConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('salePrice', isNull: false)
        .orderBy('salePrice', descending: false)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<List<ProductModel>> getRelatedProducts(
      String category, String excludeId) async {
    final snapshot = await _db
        .collection(AppConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .limit(6)
        .get();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => p.id != excludeId)
        .toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _db
        .collection(AppConstants.colCategories)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  Future<List<ReviewModel>> getReviews(String productId) async {
    final snapshot = await _db
        .collection(AppConstants.colReviews)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final batch = _db.batch();
    final reviewRef = _db.collection(AppConstants.colReviews).doc();
    batch.set(reviewRef, {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update product rating
    final productRef = _db.collection(AppConstants.colProducts).doc(productId);
    final productSnap = await productRef.get();
    final product = ProductModel.fromFirestore(productSnap);
    final newCount = product.reviewCount + 1;
    final newRating =
        ((product.rating * product.reviewCount) + rating) / newCount;

    batch.update(productRef, {
      'rating': double.parse(newRating.toStringAsFixed(1)),
      'reviewCount': newCount,
    });

    await batch.commit();
  }

  Stream<List<String>> wishlistStream(String userId) {
    return _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.subWishlist)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Future<void> toggleWishlist(String userId, String productId) async {
    final ref = _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.subWishlist)
        .doc(productId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<List<ProductModel>> getWishlistProducts(String userId) async {
    final wishSnap = await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.subWishlist)
        .get();
    final ids = wishSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final List<ProductModel> products = [];
    for (final id in ids) {
      final p = await getProduct(id);
      if (p != null) products.add(p);
    }
    return products;
  }
}
