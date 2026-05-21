import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/cache_config.dart';
import '../../../config/theme.dart';
import '../../../models/product_model.dart';

class CategorySection extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel) onCategoryTap;

  const CategorySection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('sneak') || n.contains('sport') || n.contains('run') ||
        n.contains('train')) return Icons.directions_run_rounded;
    if (n.contains('boot') || n.contains('hik') || n.contains('trek'))
      return Icons.hiking_rounded;
    if (n.contains('sandal') || n.contains('slipper') || n.contains('flip'))
      return Icons.beach_access_rounded;
    if (n.contains('formal') || n.contains('office') || n.contains('dress') ||
        n.contains('oxford')) return Icons.business_center_rounded;
    if (n.contains('kid') || n.contains('child') || n.contains('boy') ||
        n.contains('girl') || n.contains('junior'))
      return Icons.child_care_rounded;
    if (n.contains('women') || n.contains('woman') || n.contains('ladies') ||
        n.contains('heel') || n.contains('pump')) return Icons.woman_rounded;
    if (n.contains('men') || n.contains('gents'))
      return Icons.man_rounded;
    if (n.contains('loafer') || n.contains('moccas'))
      return Icons.style_outlined;
    if (n.contains('casual') || n.contains('everyday'))
      return Icons.star_border_rounded;
    if (n.contains('sale') || n.contains('deal') || n.contains('offer'))
      return Icons.local_offer_rounded;
    if (n.contains('new') || n.contains('arrival'))
      return Icons.new_releases_rounded;
    return Icons.storefront_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
          child: Row(
            children: [
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
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () => onCategoryTap(cat),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.primary.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cat.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: cat.imageUrl!,
                                cacheManager: AppCacheManager(),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _FallbackIcon(
                                  icon: _iconFor(cat.name),
                                ),
                              )
                            : _FallbackIcon(icon: _iconFor(cat.name)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;
  const _FallbackIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, color: AppColors.primary, size: 32),
    );
  }
}
