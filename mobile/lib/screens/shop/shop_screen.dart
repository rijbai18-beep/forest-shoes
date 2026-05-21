import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import 'widgets/product_card.dart';
import 'widgets/filter_bottom_sheet.dart';

class ShopScreen extends StatefulWidget {
  final String? categoryId;
  final String? gender;

  const ShopScreen({super.key, this.categoryId, this.gender});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  void _loadInitial() {
    final filter = ProductFilter(
      category: widget.categoryId,
      gender: widget.gender,
    );
    context.read<ProductProvider>().loadProducts(filter: filter, refresh: true);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadProducts();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterBottomSheet(
        currentFilter: context.read<ProductProvider>().currentFilter,
        categories: context.read<ProductProvider>().categories,
        onApply: (filter) {
          context.read<ProductProvider>().applyFilter(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final filtered = _searchQuery.isEmpty
        ? products.products
        : products.products
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search shoes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Sort chips
          _SortChips(
            current: products.currentFilter.sort,
            onSelect: (sort) {
              context.read<ProductProvider>().applyFilter(
                    products.currentFilter.copyWith(sort: sort),
                  );
            },
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} results',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Products grid/list
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<ProductProvider>().loadProducts(
                  filter: context.read<ProductProvider>().currentFilter,
                  refresh: true,
                );
              },
              child: products.isLoading && filtered.isEmpty
                  ? LayoutBuilder(
                      builder: (_, c) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: c.maxHeight,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    )
                  : products.error != null && filtered.isEmpty
                      ? LayoutBuilder(
                          builder: (_, c) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: c.maxHeight,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          size: 48, color: AppColors.error),
                                      const SizedBox(height: 12),
                                      Text(products.error!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13)),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () => context
                                            .read<ProductProvider>()
                                            .loadProducts(refresh: true),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? LayoutBuilder(
                              builder: (_, c) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: c.maxHeight,
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 64, color: AppColors.textHint),
                                        SizedBox(height: 16),
                                        Text('No products found',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : _isGridView
                              ? _ProductGrid(
                                  products: filtered,
                                  scrollCtrl: _scrollCtrl,
                                  isLoadingMore:
                                      products.isLoading && filtered.isNotEmpty,
                                )
                              : _ProductList(
                                  products: filtered,
                                  scrollCtrl: _scrollCtrl,
                                  isLoadingMore:
                                      products.isLoading && filtered.isNotEmpty,
                                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  final SortOption current;
  final void Function(SortOption) onSelect;

  const _SortChips({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = {
      SortOption.newest: 'Newest',
      SortOption.priceLow: 'Price ↑',
      SortOption.priceHigh: 'Price ↓',
      SortOption.rating: 'Rating',
      SortOption.popular: 'Popular',
    };

    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        children: options.entries.map((e) {
          final isSelected = current == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => onSelect(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List products;
  final ScrollController scrollCtrl;
  final bool isLoadingMore;

  const _ProductGrid({
    required this.products,
    required this.scrollCtrl,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }
        return ProductCard(product: products[index]);
      },
    );
  }
}

class _ProductList extends StatelessWidget {
  final List products;
  final ScrollController scrollCtrl;
  final bool isLoadingMore;

  const _ProductList({
    required this.products,
    required this.scrollCtrl,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: products.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return ProductCard(product: products[index]);
      },
    );
  }
}
