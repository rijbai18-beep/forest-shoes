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

    final banners = await OrderService().getBanners();
    if (!mounted) return;
    setState(() {
      _banners = banners;
      _loadingBanners = false;
    });

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      productProvider.listenToWishlist(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Gradient App Bar ──────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forest_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forest Shoes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (auth.isLoggedIn)
                        Text(
                          'Hello, ${auth.user?.name.split(' ').first ?? ''}!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () => context.go('/shop'),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () => context.push('/notifications'),
                ),
                if (auth.isLoggedIn)
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded,
                        color: Colors.white),
                    onPressed: () => context.push('/wishlist'),
                  ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Banner carousel ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loadingBanners
                  ? const SizedBox(
                      height: 210,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  : _banners.isNotEmpty
                      ? BannerCarousel(banners: _banners)
                      : const _DefaultHeroBanner(),
            ),

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

            // ── Featured Products ─────────────────────────────────────────
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

            // ── Hot Deals ────────────────────────────────────────────────
            if (products.saleProducts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Hot Deals',
                  subtitle: 'Limited time offers',
                  onSeeAll: () => context.go('/shop'),
                  isHot: true,
                ),
              ),
              SliverToBoxAdapter(
                child: FeaturedProductsSection(
                  products: products.saleProducts,
                  showSaleBadge: true,
                ),
              ),
            ],

            // ── Shop by Gender ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Shop by Style',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
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
      height: 210,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Forest icon watermark
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(
              Icons.forest_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'New Collection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Step Into\nNature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => ctx.go('/shop'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Shop Now →',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final bool isHot;
  final EdgeInsets padding;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.isHot = false,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 12, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isHot) ...[
                    const Text('🔥 ', style: TextStyle(fontSize: 15)),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'See All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
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
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.12),
              ),
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
                      letterSpacing: 0.2,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
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
            : const Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
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
