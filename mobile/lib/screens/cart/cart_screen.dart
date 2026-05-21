import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'widgets/cart_item_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _applyingCoupon = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _applyingCoupon = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon validation — connect Firebase Functions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _applyingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const _CartAppBar(itemCount: 0, onClear: null),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textHint),
              ),
              const SizedBox(height: 20),
              const Text('Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Add some shoes to get started!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 28),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () => context.go('/shop'),
                  child: const Text('Start Shopping'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const deliveryFeeBase = AppConstants.defaultDeliveryFee;
    final deliveryFee = cart.calculateDeliveryFee(deliveryFeeBase);
    final total = cart.calculateTotal(deliveryFee);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _CartAppBar(
        itemCount: cart.itemCount,
        onClear: () => _confirmClearCart(context),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                // Items
                ...cart.items.map((item) => CartItemWidget(
                      item: item,
                      onRemove: () => cart.removeItem(item.cartKey),
                      onQuantityChanged: (qty) => cart.updateQuantity(item.cartKey, qty),
                    )),

                const SizedBox(height: 16),

                // Promo code
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: cart.appliedCouponCode != null
                      ? Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${cart.appliedCouponCode} applied! -Rs ${cart.couponDiscount.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: cart.removeCoupon,
                              child: const Icon(Icons.close_rounded, color: AppColors.success, size: 18),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponCtrl,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Enter promo code',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _applyingCoupon ? null : _applyCoupon,
                              child: _applyingCoupon
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Apply', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 12),

                // Order note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Note', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 10),
                      TextField(
                        maxLines: 2,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(hintText: 'Any special instructions?'),
                        onChanged: cart.setNote,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Sticky bottom summary ────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryRow('Subtotal', cart.subtotal),
                if (cart.engravingTotal > 0) _SummaryRow('Engraving', cart.engravingTotal),
                if (cart.couponDiscount > 0) _SummaryRow('Discount', -cart.couponDiscount, isGreen: true),
                _SummaryRow('Delivery', deliveryFee, note: deliveryFee == 0 ? 'Free!' : null),
                if (cart.subtotal < AppConstants.freeDeliveryThreshold)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Text(
                      'Add Rs ${(AppConstants.freeDeliveryThreshold - cart.subtotal).toStringAsFixed(0)} more for free delivery',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text(
                      'Rs.${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (!auth.isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Please sign in to checkout.',
                              style: TextStyle(color: AppColors.warning, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CheckoutButton(
                    label: 'Sign In to Checkout',
                    onPressed: () => context.push('/login'),
                  ),
                ] else
                  _CheckoutButton(
                    label: 'Proceed to Checkout',
                    onPressed: () => context.push('/checkout'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cart?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int itemCount;
  final VoidCallback? onClear;

  const _CartAppBar({required this.itemCount, required this.onClear});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          const Text('Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (itemCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$itemCount item${itemCount > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text('Clear', style: TextStyle(color: AppColors.sale, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── Checkout button ───────────────────────────────────────────────────────────

class _CheckoutButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CheckoutButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String? note;
  final bool isGreen;

  const _SummaryRow(this.label, this.amount, {this.note, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          if (note != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(note!, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
          Text(
            '${amount < 0 ? '-' : ''}Rs.${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isGreen ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
