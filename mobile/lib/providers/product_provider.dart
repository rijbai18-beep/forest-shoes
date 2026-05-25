import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _saleProducts = [];
  List<CategoryModel> _categories = [];
  List<String> _wishlistIds = [];
  StreamSubscription<List<String>>? _wishlistSub;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDoc;
  ProductFilter _currentFilter = const ProductFilter();

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get saleProducts => _saleProducts;
  List<CategoryModel> get categories => _categories;
  List<String> get wishlistIds => _wishlistIds;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  ProductFilter get currentFilter => _currentFilter;

  bool isWishlisted(String productId) => _wishlistIds.contains(productId);

  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getFeaturedProducts(),
        _service.getSaleProducts(),
        _service.getCategories(),
      ]);
      _featuredProducts = results[0] as List<ProductModel>;
      _saleProducts = results[1] as List<ProductModel>;
      _categories = results[2] as List<CategoryModel>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({ProductFilter? filter, bool refresh = false}) async {
    if (filter != null) _currentFilter = filter;
    if (refresh) {
      _products = [];
      _hasMore = true;
      _lastDoc = null;
    }
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final (newProducts, lastDoc) =
          await _service.getProducts(_currentFilter, startAfter: _lastDoc);
      _products.addAll(newProducts);
      _lastDoc = lastDoc;
      _hasMore = newProducts.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter(ProductFilter filter) async {
    _currentFilter = filter;
    await loadProducts(refresh: true);
  }

  void listenToWishlist(String userId) {
    _wishlistSub?.cancel();
    _wishlistSub = _service.wishlistStream(userId).listen((ids) {
      _wishlistIds = ids;
      notifyListeners();
    });
  }

  void clearWishlist() {
    _wishlistSub?.cancel();
    _wishlistSub = null;
    _wishlistIds = [];
    notifyListeners();
  }

  Future<void> toggleWishlist(String userId, String productId) async {
    await _service.toggleWishlist(userId, productId);
  }

  @override
  void dispose() {
    _wishlistSub?.cancel();
    super.dispose();
  }
}
