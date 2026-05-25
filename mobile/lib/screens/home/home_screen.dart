import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/order_service.dart';
import '../../models/banner_model.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/category_section.dart';
import 'widgets/featured_products_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BannerModel> _banners = [];
  bool _loadingBanners = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadHomeData();

    try {
      final banners = await OrderService().getBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners;
        _loadingBanners = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBanners = false);
    }

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      productProvider.listenToWishlist(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Search + location header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFF5F5F5),
                padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search pill
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/shop'),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 16),
                                  Icon(Icons.search_rounded,
                                      color: AppColors.textHint, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Search shoes...',
                                      style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 15),
                                    ),
                                  ),
                                  Icon(Icons.camera_alt_outlined,
                                      color: AppColors.textHint, size: 20),
                                  SizedBox(width: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Notification bell
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: AppColors.textPrimary, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Location row
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Deliver to  ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            auth.isLoggedIn
                                ? (auth.user?.name ?? 'Forest Shoes, Mauritius')
                                : 'Forest Shoes, Mauritius',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Banner carousel ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loadingBanners
                  ? const SizedBox(
                      height: 220,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  : _banners.isNotEmpty
                      ? BannerCarousel(banners: _banners)
                      : const _DefaultHeroBanner(),
            ),

            // ── Special Offers (sale products) ────────────────────────────
            if (products.saleProducts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Special Offers',
                  onSeeAll: () => context.go('/shop'),
                ),
              ),
              SliverToBoxAdapter(
                child: FeaturedProductsSection(
                  products: products.saleProducts,
                  showSaleBadge: true,
                ),
              ),
            ],

            // ── Categories ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: products.isLoading && products.categories.isEmpty
                  ? const LoadingWidget()
                  : CategorySection(
                      categories: products.categories,
                      onCategoryTap: (cat) =>
                          context.go('/shop?category=${cat.id}'),
                    ),
            ),

            // ── Featured ─────────────────────────────────────────────────
            if (products.featuredProducts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Featured',
                  onSeeAll: () => context.go('/shop'),
                ),
              ),
              SliverToBoxAdapter(
                child: FeaturedProductsSection(
                  products: products.featuredProducts,
                ),
              ),
            ],

            // ── Shop by Style ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Shop by Style',
                      onSeeAll: () => context.go('/shop'),
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderCard(
                            title: "Men's",
                            icon: Icons.man_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.go('/shop?gender=men'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GenderCard(
                            title: "Women's",
                            icon: Icons.woman_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC2185B), Color(0xFF880E4F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.go('/shop?gender=women'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GenderCard(
                      title: "Kids'",
                      icon: Icons.child_care_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.go('/shop?gender=kids'),
                      isWide: true,
                    ),
                  ],
                ),
              ),
            ),

            // ── USP Section ───────────────────────────────────────────────
            const SliverToBoxAdapter(child: _UspSection()),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Default Hero Banner ───────────────────────────────────────────────────────

class _DefaultHeroBanner extends StatelessWidget {
  const _DefaultHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: const Color(0xFF1B5E20),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(
              Icons.forest_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Step Into\nNature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get discounts up to 50% on\npremium footwear',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => ctx.go('/shop'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Shop Now',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Gender Card ───────────────────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool isWide;

  const _GenderCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isWide ? 72 : 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(icon,
                  size: 80, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isWide) ...[
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 14),
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

// ── USP Section ───────────────────────────────────────────────────────────────

class _UspSection extends StatelessWidget {
  const _UspSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          _UspItem(
            icon: Icons.local_shipping_outlined,
            title: 'Free Delivery',
            subtitle: 'On orders above Rs 300',
            isFirst: true,
          ),
          _UspItem(
            icon: Icons.verified_outlined,
            title: 'Authentic Products',
            subtitle: '100% genuine footwear',
          ),
          _UspItem(
            icon: Icons.support_agent_outlined,
            title: '24/7 Support',
            subtitle: 'We are always here for you',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _UspItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  const _UspItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}
