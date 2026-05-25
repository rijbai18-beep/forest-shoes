import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import '../shop/widgets/product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<ProductModel> _products = [];
  bool _loading = true;
  List<String> _lastIds = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload products whenever the wishlisted IDs change in the provider.
    final ids = context.watch<ProductProvider>().wishlistIds;
    if (ids.length != _lastIds.length ||
        ids.any((id) => !_lastIds.contains(id))) {
      _lastIds = List.of(ids);
      _loadWishlist();
    }
  }

  Future<void> _loadWishlist() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final products = await ProductService().getWishlistProducts(uid);
    if (mounted) {
      setState(() {
        _products = products;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wishlist')),
      body: !auth.isLoggedIn
          ? _NotLoggedIn()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadWishlist,
              child: _loading
                  ? LayoutBuilder(
                      builder: (_, c) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: c.maxHeight,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    )
                  : _products.isEmpty
                      ? LayoutBuilder(
                          builder: (_, c) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: c.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite_border_rounded,
                                        size: 64, color: AppColors.textHint),
                                    const SizedBox(height: 16),
                                    const Text('Your wishlist is empty',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600)),
                                    const Text('Save products you love here',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => context.go('/shop'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Browse Products'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (_, i) =>
                              ProductCard(product: _products[i]),
                        ),
            ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('Sign in to see your wishlist',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Save your favourite products',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
