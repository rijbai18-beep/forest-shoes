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
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/common/custom_button.dart';
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
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size.')));
      return;
    }
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a color.')));
      return;
    }

    context.read<CartProvider>().addItem(CartItemModel(
          productId: _product!.id,
          name: _product!.name,
          imageUrl: _product!.images.isNotEmpty ? _product!.images.first : '',
          price: _product!.effectivePrice,
          size: _selectedSize!,
          color: _selectedColor!,
          quantity: _quantity,
          hasEngraving: _engravingEnabled && _engravingText != null,
          engravingText: _engravingEnabled ? _engravingText : null,
          engravingFee: _product!.engravingFee,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final isWishlisted = productProvider.isWishlisted(_product!.id);
    final p = _product!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Image gallery app bar
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (auth.isLoggedIn)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: isWishlisted ? AppColors.sale : AppColors.textHint,
                    ),
                  ),
                  onPressed: () =>
                      productProvider.toggleWishlist(auth.user!.uid, p.id),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 350,
                      viewportFraction: 1.0,
                      onPageChanged: (i, _) =>
                          setState(() => _imageIndex = i),
                    ),
                    items: p.images.isEmpty
                        ? [
                            Container(
                              color: AppColors.background,
                              child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 80,
                                  color: AppColors.textHint),
                            )
                          ]
                        : p.images
                            .map((url) => CachedNetworkImage(
                                  imageUrl: url,
                                  cacheManager: AppCacheManager(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ))
                            .toList(),
                  ),
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          p.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _imageIndex == i ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _imageIndex == i
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (p.isOnSale)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${p.discountPercentage.toInt()}% OFF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (p.isOnSale)
                              Text(
                                'Rs ${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 14,
                                ),
                              ),
                            Text(
                              'Rs ${p.effectivePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: p.isOnSale
                                    ? AppColors.sale
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Rating
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: p.rating,
                          itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold),
                          itemCount: 5,
                          itemSize: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.rating.toStringAsFixed(1)} (${p.reviewCount} reviews)',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),

                    // Stock
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          p.inStock
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color:
                              p.inStock ? AppColors.success : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.inStock
                              ? '${p.stock} in stock'
                              : 'Out of stock',
                          style: TextStyle(
                            color: p.inStock
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const _SectionDivider(),
                    const SizedBox(height: 16),

                    // Color selection
                    if (p.colors.isNotEmpty) ...[
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                            onTap: () =>
                                setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Size selection
                    if (p.sizes.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            'Size',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _showSizeGuide,
                            icon: const Icon(Icons.straighten_rounded, size: 14),
                            label: const Text('Size Guide'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
                              width: 56,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
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
                      const SizedBox(height: 20),
                    ],

                    // Quantity
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 14,
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

                    // Engraving
                    if (p.hasEngraving) ...[
                      const SizedBox(height: 20),
                      EngravingWidget(
                        enabled: _engravingEnabled,
                        initialText: _engravingText,
                        onChanged: (text) {
                          setState(() {
                            _engravingText = text;
                            _engravingEnabled = text != null;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    const _SectionDivider(),
                    const SizedBox(height: 16),

                    // Description
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

                    // Custom fields
                    if (p.customFields != null &&
                        p.customFields!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...p.customFields!.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text('${e.key}: ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(e.value.toString(),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          )),
                    ],

                    // Reviews section
                    const SizedBox(height: 24),
                    const _SectionDivider(),
                    const SizedBox(height: 16),
                    _ReviewsSection(
                      reviews: _reviews,
                      productId: p.id,
                      onReviewAdded: _loadProduct,
                    ),

                    // Related products
                    if (_related.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionDivider(),
                      const SizedBox(height: 16),
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
                        height: 250,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _related.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 170,
                            child: ProductCard(product: _related[i]),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: p.inStock
              ? Row(
                  children: [
                    // Wishlist button
                    if (auth.isLoggedIn)
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isWishlisted
                                  ? AppColors.sale
                                  : AppColors.divider,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isWishlisted
                                ? AppColors.sale
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => productProvider.toggleWishlist(
                              auth.user!.uid, p.id),
                        ),
                      ),
                    // Add to cart button
                    Expanded(
                      child: ElevatedButton(
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
                              'Add to Cart  •  Rs ${(p.effectivePrice * _quantity + (_engravingEnabled && _engravingText != null ? p.engravingFee * _quantity : 0)).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
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
                    child: const Text(
                      'Out of Stock',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
            Text('Size Guide',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: AppColors.divider),
              children: const [
                TableRow(children: [
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('EU', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('UK', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('US', style: TextStyle(fontWeight: FontWeight.w700))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('CM', style: TextStyle(fontWeight: FontWeight.w700))),
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

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int max;
  final void Function(int) onChanged;

  const _QuantitySelector({
    required this.quantity,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove_rounded,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        _QtyBtn(
          icon: Icons.add_rounded,
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? AppColors.primary : AppColors.textHint,
          size: 20,
        ),
      ),
    );
  }
}

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
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write Review'),
              onPressed: () => _writeReview(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
        const SnackBar(content: Text('Please log in to write a review.')),
      );
      return;
    }

    double rating = 5.0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
              ),
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ],
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          const Divider(),
        ],
      ),
    );
  }
}
