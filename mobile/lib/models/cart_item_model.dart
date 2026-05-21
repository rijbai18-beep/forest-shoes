import 'dart:convert';

class CartItemModel {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String size;
  final String color;
  int quantity;
  final bool hasEngraving;
  final String? engravingText;
  final double engravingFee;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.size,
    required this.color,
    this.quantity = 1,
    this.hasEngraving = false,
    this.engravingText,
    this.engravingFee = 0.0,
  });

  String get cartKey => '$productId-$size-$color-${engravingText ?? ''}';

  double get itemTotal => (price * quantity) + (hasEngraving ? engravingFee * quantity : 0);
  double get engravingTotal => hasEngraving ? engravingFee * quantity : 0;

  CartItemModel copyWith({
    int? quantity,
    String? engravingText,
    bool? hasEngraving,
  }) =>
      CartItemModel(
        productId: productId,
        name: name,
        imageUrl: imageUrl,
        price: price,
        size: size,
        color: color,
        quantity: quantity ?? this.quantity,
        hasEngraving: hasEngraving ?? this.hasEngraving,
        engravingText: engravingText ?? this.engravingText,
        engravingFee: engravingFee,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'size': size,
        'color': color,
        'quantity': quantity,
        'hasEngraving': hasEngraving,
        'engravingText': engravingText,
        'engravingFee': engravingFee,
      };

  factory CartItemModel.fromMap(Map<String, dynamic> map) => CartItemModel(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        size: map['size'] ?? '',
        color: map['color'] ?? '',
        quantity: map['quantity'] ?? 1,
        hasEngraving: map['hasEngraving'] ?? false,
        engravingText: map['engravingText'],
        engravingFee: (map['engravingFee'] ?? 0).toDouble(),
      );

  String toJson() => jsonEncode(toMap());
  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(jsonDecode(source));
}
