import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart_item_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool showSaleBadge;

  const ProductCard({
    super.key,
    required this.product,
    this.showSaleBadge = false,
  });

  void _showQuickView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickViewSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final isWishlisted = productProvider.isWishlisted(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + overlays ──────────────────────────────────────────
            Stack(
              children: [
                // Main image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first
                        : '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: const Color(0xFFF1F8E9),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: const Color(0xFFF1F8E9),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textHint,
                        size: 36,
                      ),
                    ),
                  ),
                ),

                // Sale badge
                if (product.isOnSale || showSaleBadge && product.isOnSale)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Out of stock overlay
                if (!product.inStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Wishlist button
                if (auth.isLoggedIn)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => productProvider.toggleWishlist(
                          auth.user!.uid, product.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: isWishlisted
                              ? AppColors.sale
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),

                // Engraving badge
                if (product.hasEngraving)
                  Positioned(
                    bottom: 36,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Engravable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Quick View button (bottom gradient overlay)
                if (product.inStock)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showQuickView(context),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(0)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_outlined,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            const Text(
                              'Quick View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Product info ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (product.isOnSale) ...[
                        Text(
                          'Rs ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        'Rs ${product.effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: product.isOnSale
                              ? AppColors.sale
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick View Bottom Sheet ───────────────────────────────────────────────────

class _QuickViewSheet extends StatefulWidget {
  final ProductModel product;
  const _QuickViewSheet({required this.product});

  @override
  State<_QuickViewSheet> createState() => _QuickViewSheetState();
}

class _QuickViewSheetState extends State<_QuickViewSheet> {
  String? _selectedSize;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p.sizes.isNotEmpty) _selectedSize = p.sizes.first;
    if (p.colors.isNotEmpty) _selectedColor = p.colors.first;
  }

  void _addToCart() {
    if (_selectedSize == null || _selectedColor == null) return;
    context.read<CartProvider>().addItem(CartItemModel(
          productId: widget.product.id,
          name: widget.product.name,
          imageUrl: widget.product.images.isNotEmpty
              ? widget.product.images.first
              : '',
          price: widget.product.effectivePrice,
          size: _selectedSize!,
          color: _selectedColor!,
          quantity: 1,
          hasEngraving: false,
          engravingText: null,
          engravingFee: 0,
        ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image + info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: p.images.isNotEmpty ? p.images.first : '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: const Color(0xFFF1F8E9),
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: AppColors.textHint),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (p.isOnSale) ...[
                                  Text(
                                    'Rs ${p.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  'Rs ${p.effectivePrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: p.isOnSale
                                        ? AppColors.sale
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (p.rating > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < p.rating.round()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 14,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${p.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Size selector
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Select Size',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.sizes.map((size) {
                        final isSelected = _selectedSize == size;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSize = size),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Color selector
                  if (p.colors.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Select Color',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              color,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // CTA buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/product/${p.id}');
                    },
                    child: const Text(
                      'Full Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _addToCart,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Add to Cart',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
