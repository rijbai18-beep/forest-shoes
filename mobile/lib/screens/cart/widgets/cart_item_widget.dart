import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item_model.dart';

class CartItemWidget extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final void Function(int) onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.divider,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.background,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textHint),
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag('Size: ${item.size}'),
                      _Tag('Color: ${item.color}'),
                    ],
                  ),
                  if (item.hasEngraving && item.engravingText != null) ...[
                    const SizedBox(height: 4),
                    _Tag('Engraving: "${item.engravingText}"',
                        color: AppColors.primary),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (item.hasEngraving)
                            Text(
                              '+Rs ${item.engravingFee.toStringAsFixed(0)} engraving',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                            ),
                        ],
                      ),
                      const Spacer(),
                      _QuantityControl(
                        quantity: item.quantity,
                        onChanged: onQuantityChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag(this.text, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final void Function(int) onChanged;

  const _QuantityControl({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(
              Icons.remove_rounded,
              size: 16,
              color:
                  quantity > 1 ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$quantity',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        InkWell(
          onTap: () => onChanged(quantity + 1),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add_rounded,
                size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
