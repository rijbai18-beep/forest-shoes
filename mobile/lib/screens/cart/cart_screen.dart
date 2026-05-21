import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/custom_button.dart';
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
      // Call Firebase Function to validate coupon
      // This is a placeholder - in production use Firebase callable functions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon validation - connect Firebase Functions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 80, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text('Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Add some shoes to get started!',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/shop'),
                child: const Text('Start Shopping'),
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
      appBar: AppBar(
        title: Text('Cart (${cart.itemCount})'),
        actions: [
          TextButton(
            onPressed: () => _confirmClearCart(context),
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cart items
          ...cart.items.map((item) => CartItemWidget(
                item: item,
                onRemove: () => cart.removeItem(item.cartKey),
                onQuantityChanged: (qty) =>
                    cart.updateQuantity(item.cartKey, qty),
              )),

          const SizedBox(height: 16),

          // Coupon section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Promo Code',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (cart.appliedCouponCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${cart.appliedCouponCode} applied! -Rs ${cart.couponDiscount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.success, size: 18),
                            onPressed: cart.removeCoupon,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter promo code',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyingCoupon ? null : _applyCoupon,
                          child: _applyingCoupon
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Order note
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Note (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Any special instructions?',
                    ),
                    onChanged: cart.setNote,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Price summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow('Subtotal', cart.subtotal),
                  if (cart.engravingTotal > 0)
                    _SummaryRow('Engraving', cart.engravingTotal),
                  if (cart.couponDiscount > 0)
                    _SummaryRow('Discount', -cart.couponDiscount,
                        isGreen: true),
                  _SummaryRow(
                    'Delivery',
                    deliveryFee,
                    note: deliveryFee == 0 ? 'Free!' : null,
                  ),
                  if (cart.subtotal < AppConstants.freeDeliveryThreshold)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Add Rs ${(AppConstants.freeDeliveryThreshold - cart.subtotal).toStringAsFixed(0)} more for free delivery',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      Text(
                        'Rs ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Checkout button
          if (!auth.isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please sign in to proceed with checkout.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Sign In to Checkout',
              onPressed: () => context.push('/login'),
              icon: Icons.login_rounded,
            ),
          ] else ...[
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: () => context.push('/checkout'),
              icon: Icons.arrow_forward_rounded,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String? note;
  final bool isGreen;

  const _SummaryRow(this.label, this.amount,
      {this.note, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          if (note != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(note!,
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          Text(
            '${amount < 0 ? '-' : ''}Rs ${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isGreen ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
