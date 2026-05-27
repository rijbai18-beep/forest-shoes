import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/cache_config.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../config/test_keys.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import 'widgets/engraving_widget.dart';
import 'widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductService();
  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  List<ProductModel> _related = [];
  bool _loading = true;

  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  String? _engravingText;
  bool _engravingEnabled = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await _service.getProduct(widget.productId);
    if (product == null) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      _service.getReviews(product.id),
      _service.getRelatedProducts(product.category, product.id),
    ]);
    if (mounted) {
      setState(() {
        _product = product;
        _reviews = results[0] as List<ReviewModel>;
        _related = results[1] as List<ProductModel>;
        _loading = false;
        if (product.colors.isNotEmpty) _selectedColor = product.colors.first;
        if (product.sizes.isNotEmpty) _selectedSize = product.sizes.first;
      });
    }
  }

  void _addToCart() {
    if (_product!.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size.')));
      return;
    }
    if (_product!.colors.isNotEmpty && _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a color.')));
      return;
    }
    context.read<CartProvider>().addItem(CartItemModel(
          productId: _product!.id,
          name: _product!.name,
          imageUrl: _product!.images.isNotEmpty ? _product!.images.first : '',
          price: _product!.effectivePrice,
          size: _selectedSize,
          color: _selectedColor ?? '',
          quantity: _quantity,
          hasEngraving: _engravingEnabled && _engravingText != null,
          engravingText: _engravingEnabled ? _engravingText : null,
          engravingFee: _product!.engravingFee,
        ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart!'),
        action: SnackBarAction(
            label: 'View Cart', onPressed: () => context.go('/cart')),
      ),
    );
  }

  double get _totalPrice =>
      _product!.effectivePrice * _quantity +
      (_engravingEnabled && _engravingText != null
          ? _product!.engravingFee * _quantity
          : 0);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(backgroundColor: const Color(0xFFF5F5F5)),
        body: const Center(child: Text('Product not found')),
      );
    }

    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final isWishlisted = productProvider.isWishlisted(_product!.id);
    final p = _product!;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image section (white card) ────────────────────────────
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: topPad + 56),
                      // Carousel
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: p.images.length > 1,
                          onPageChanged: (i, _) =>
                              setState(() => _imageIndex = i),
                        ),
                        items: p.images.isEmpty
                            ? [
                                const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 80,
                                        color: AppColors.textHint),
                                  ),
                                )
                              ]
                            : p.images
                                .map((url) => CachedNetworkImage(
                                      imageUrl: url,
                                      cacheManager: AppCacheManager(),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary)),
                                      errorWidget: (_, __, ___) => const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.textHint,
                                          size: 60),
                                    ))
                                .toList(),
                      ),
                      // Dot indicators
                      if (p.images.length > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            p.images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: _imageIndex == i ? 20 : 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: _imageIndex == i
                                    ? AppColors.primary
                                    : const Color(0xFFCCCCCC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Thumbnail strip
                      if (p.images.length > 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: p.images.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () =>
                                  setState(() => _imageIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _imageIndex == i
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  color: const Color(0xFFF5F5F5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: p.images[i],
                                    cacheManager: AppCacheManager(),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Name + Price card ─────────────────────────────────────
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sale badge
                      if (p.isOnSale)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sale,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${p.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),

                      // Name
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${p.effectivePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: p.isOnSale
                                  ? AppColors.sale
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (p.isOnSale) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                'Rs ${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rating + stock row
                      Row(
                        children: [
                          if (p.rating > 0) ...[
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              p.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              '  (${p.reviewCount} reviews)',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.inStock
                                  ? AppColors.success
                                      .withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.inStock
                                  ? '${p.stock} in stock'
                                  : 'Out of stock',
                              style: TextStyle(
                                color: p.inStock
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Color + Size + Quantity card ──────────────────────────
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color
                      if (p.colors.isNotEmpty) ...[
                        _OptionLabel(label: 'Color', value: _selectedColor),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.colors.map((color) {
                            final sel = _selectedColor == color;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  color,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 20),
                      ],

                      // Size
                      if (p.sizes.isNotEmpty) ...[
                        Row(
                          children: [
                            _OptionLabel(
                                label: 'Size', value: _selectedSize),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showSizeGuide,
                              child: const Row(
                                children: [
                                  Icon(Icons.straighten_rounded,
                                      size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Size Guide',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.sizes.map((size) {
                            final sel = _selectedSize == size;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSize = size),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 56,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: sel
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 20),
                      ],

                      // Quantity
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          _QuantitySelector(
                            quantity: _quantity,
                            max: p.stock,
                            onChanged: (v) => setState(() => _quantity = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Engraving ─────────────────────────────────────────────
                if (p.hasEngraving) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EngravingWidget(
                      enabled: _engravingEnabled,
                      initialText: _engravingText,
                      imageUrl: p.images.isNotEmpty ? p.images.first : null,
                      onChanged: (text) {
                        setState(() {
                          _engravingText = text;
                          _engravingEnabled = text != null;
                        });
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ── Description card ──────────────────────────────────────
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.7,
                          fontSize: 14,
                        ),
                      ),
                      if (p.customFields != null &&
                          p.customFields!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 14),
                        ...p.customFields!.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text('${e.key}: ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary)),
                                  Expanded(
                                    child: Text(e.value.toString(),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Reviews card ──────────────────────────────────────────
                _Card(
                  child: _ReviewsSection(
                    reviews: _reviews,
                    productId: p.id,
                    onReviewAdded: _loadProduct,
                  ),
                ),

                // ── Related products ──────────────────────────────────────
                if (_related.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You May Also Like',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 290,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _related.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => SizedBox(
                              width: 168,
                              child: ProductCard(product: _related[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Space for bottom bar
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Floating back + wishlist buttons ────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            child: _FloatingIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
            ),
          ),
          if (auth.isLoggedIn)
            Positioned(
              top: topPad + 8,
              right: 16,
              child: _FloatingIconButton(
                icon: isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor:
                    isWishlisted ? AppColors.sale : AppColors.textSecondary,
                onTap: () =>
                    productProvider.toggleWishlist(auth.user!.uid, p.id),
              ),
            ),
        ],
      ),

      // ── Bottom CTA bar ─────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -4)),
            ],
          ),
          child: p.inStock
              ? Row(
                  children: [
                    // Wishlist shortcut
                    if (auth.isLoggedIn)
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isWishlisted
                                ? AppColors.sale
                                : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isWishlisted
                                ? AppColors.sale
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          onPressed: () => productProvider.toggleWishlist(
                              auth.user!.uid, p.id),
                        ),
                      ),
                    // Add to cart
                    Expanded(
                      child: ElevatedButton(
                        key: const ValueKey(TestKeys.addToCartButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _addToCart,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add to Cart  •  Rs ${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textHint,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: null,
                    child: const Text('Out of Stock',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
        ),
      ),
    );
  }

  void _showSizeGuide() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Size Guide', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: AppColors.divider),
              children: const [
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('EU', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(padding: EdgeInsets.all(8), child: Text('UK', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(padding: EdgeInsets.all(8), child: Text('US', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(padding: EdgeInsets.all(8), child: Text('CM', style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('40')),
                  Padding(padding: EdgeInsets.all(8), child: Text('6.5')),
                  Padding(padding: EdgeInsets.all(8), child: Text('7.5')),
                  Padding(padding: EdgeInsets.all(8), child: Text('25.5')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('42')),
                  Padding(padding: EdgeInsets.all(8), child: Text('8')),
                  Padding(padding: EdgeInsets.all(8), child: Text('9')),
                  Padding(padding: EdgeInsets.all(8), child: Text('26.5')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('44')),
                  Padding(padding: EdgeInsets.all(8), child: Text('9.5')),
                  Padding(padding: EdgeInsets.all(8), child: Text('10.5')),
                  Padding(padding: EdgeInsets.all(8), child: Text('28')),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Floating icon button (back / wishlist) ────────────────────────────────────

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _FloatingIconButton({
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon,
            size: 20, color: iconColor ?? AppColors.textPrimary),
      ),
    );
  }
}

// ── Option label (Color / Size) ───────────────────────────────────────────────

class _OptionLabel extends StatelessWidget {
  final String label;
  final String? value;

  const _OptionLabel({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          Text(
            '— $value',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

// ── Quantity selector ─────────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int max;
  final void Function(int) onChanged;

  const _QuantitySelector(
      {required this.quantity, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove_rounded,
          enabled: quantity > 1,
          onTap: () => onChanged(quantity - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        _QtyBtn(
          icon: Icons.add_rounded,
          enabled: quantity < max,
          onTap: () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String productId;
  final VoidCallback onReviewAdded;

  const _ReviewsSection({
    required this.reviews,
    required this.productId,
    required this.onReviewAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reviews (${reviews.length})',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _writeReview(context),
              child: const Row(
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Write Review',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No reviews yet. Be the first to review!',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...reviews.take(5).map((r) => _ReviewItem(review: r)),
      ],
    );
  }

  void _writeReview(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to write a review.')));
      return;
    }
    double rating = 5.0;
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Write a Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Rating'),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: AppColors.gold),
              onRatingUpdate: (r) => rating = r,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Share your experience...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final service = ProductService();
                  await service.addReview(
                    productId: productId,
                    userId: auth.user!.uid,
                    userName: auth.user!.name,
                    rating: rating,
                    comment: commentCtrl.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  onReviewAdded();
                },
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  RatingBarIndicator(
                    rating: review.rating,
                    itemSize: 14,
                    itemBuilder: (_, __) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment,
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}
