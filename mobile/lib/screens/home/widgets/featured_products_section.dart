import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../shop/widgets/product_card.dart';

class FeaturedProductsSection extends StatelessWidget {
  final List<ProductModel> products;
  final bool showSaleBadge;

  const FeaturedProductsSection({
    super.key,
    required this.products,
    this.showSaleBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 175,
          child: ProductCard(
            product: products[index],
            showSaleBadge: showSaleBadge,
          ),
        ),
      ),
    );
  }
}
