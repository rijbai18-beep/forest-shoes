import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../config/constants.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items = [];
  String? _appliedCouponCode;
  String? _appliedCouponId;
  double _couponDiscount = 0.0;
  String? _note;

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  String? get appliedCouponCode => _appliedCouponCode;
  String? get appliedCouponId => _appliedCouponId;
  double get couponDiscount => _couponDiscount;
  String? get note => _note;

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  double get engravingTotal =>
      _items.fold(0.0, (sum, item) => sum + item.engravingTotal);

  double calculateDeliveryFee(double deliveryTypeFee) {
    final itemsTotal = subtotal - _couponDiscount;
    if (itemsTotal >= AppConstants.freeDeliveryThreshold) return 0.0;
    return deliveryTypeFee > 0 ? deliveryTypeFee : AppConstants.defaultDeliveryFee;
  }

  double calculateTotal(double deliveryFee) =>
      subtotal + engravingTotal + deliveryFee - _couponDiscount;

  CartProvider() {
    _loadFromPrefs();
  }

  void addItem(CartItemModel item) {
    final index = _items.indexWhere((e) => e.cartKey == item.cartKey);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _items.removeWhere((e) => e.cartKey == cartKey);
    _saveToPrefs();
    notifyListeners();
  }

  void updateQuantity(String cartKey, int quantity) {
    if (quantity <= 0) {
      removeItem(cartKey);
      return;
    }
    final index = _items.indexWhere((e) => e.cartKey == cartKey);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void applyCoupon({
    required String code,
    required String couponId,
    required double discount,
  }) {
    _appliedCouponCode = code;
    _appliedCouponId = couponId;
    _couponDiscount = discount;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _appliedCouponId = null;
    _couponDiscount = 0.0;
    notifyListeners();
  }

  void setNote(String? note) {
    _note = note;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCouponCode = null;
    _appliedCouponId = null;
    _couponDiscount = 0.0;
    _note = null;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(AppConstants.prefCartItems, encoded);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.prefCartItems);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _items =
          list.map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
      notifyListeners();
    }
  }
}
