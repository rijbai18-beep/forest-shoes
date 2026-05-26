import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../models/banner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();

  // Address fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();

  List<PaymentTypeModel> _paymentTypes = [];
  List<DeliveryTypeModel> _deliveryTypes = [];
  PaymentTypeModel? _selectedPayment;
  DeliveryTypeModel? _selectedDelivery;
  Map<String, dynamic> _settings = {};
  bool _loadingOptions = true;
  bool _placingOrder = false;
  bool _saveAddress = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _prefillAddress();
  }

  void _prefillAddress() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.phone ?? '';
    if (user.addresses.isNotEmpty) {
      final addr = user.addresses.first;
      _line1Ctrl.text = addr.line1;
      _line2Ctrl.text = addr.line2 ?? '';
      _cityCtrl.text = addr.city;
      _postcodeCtrl.text = addr.postcode;
    }
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      _orderService.getPaymentTypes(),
      _orderService.getDeliveryTypes(),
      _orderService.getSettings(),
    ]);
    if (!mounted) return;
    setState(() {
      _paymentTypes = results[0] as List<PaymentTypeModel>;
      _deliveryTypes = results[1] as List<DeliveryTypeModel>;
      _settings = results[2] as Map<String, dynamic>;
      if (_paymentTypes.isNotEmpty) _selectedPayment = _paymentTypes.first;
      if (_deliveryTypes.isNotEmpty) _selectedDelivery = _deliveryTypes.first;
      _loadingOptions = false;
    });
  }

  double _computeDeliveryFee() {
    // Each delivery type already carries its own fee configured by the admin.
    // Returning that fee directly is the correct behaviour — free-delivery
    // promotions should be expressed as a delivery option with fee = 0 in the
    // admin panel, not by silently zeroing out the selected fee here.
    return _selectedDelivery?.fee ?? 0.0;
  }

  Future<void> _placeOrder(double deliveryFee) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayment == null || _selectedDelivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select payment and delivery options.')),
      );
      return;
    }

    setState(() => _placingOrder = true);

    try {
      final auth = context.read<AuthProvider>();
      final cart = context.read<CartProvider>();
      final address = AddressModel(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        line1: _line1Ctrl.text,
        line2: _line2Ctrl.text.isEmpty ? null : _line2Ctrl.text,
        city: _cityCtrl.text,
        postcode: _postcodeCtrl.text,
      );

      final orderId = await _orderService.placeOrder(
        userId: auth.user!.uid,
        items: cart.items.toList(),
        subtotal: cart.subtotal,
        deliveryFee: deliveryFee,
        engravingFee: cart.engravingTotal,
        couponDiscount: cart.couponDiscount,
        total: cart.calculateTotal(deliveryFee),
        paymentType: _selectedPayment!.name,
        paymentTypeId: _selectedPayment!.id,
        deliveryType: _selectedDelivery!.name,
        deliveryTypeId: _selectedDelivery!.id,
        address: address,
        note: cart.note,
        couponCode: cart.appliedCouponCode,
      );

      if (_saveAddress && auth.user!.addresses.isEmpty) {
        await auth.updateAddresses([address]);
      }

      cart.clearCart();

      if (!mounted) return;
      _showOrderSuccess(orderId);
    } catch (e) {
      if (!mounted) return;
      // Stock-validation exceptions carry user-readable messages; strip the
      // Dart "Exception: " prefix before showing them. All other failures get
      // a generic friendly message.
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ')
          ? raw.replaceFirst('Exception: ', '')
          : 'We could not place your order. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _placingOrder = false);
    }
  }

  void _showOrderSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 80),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Order #${orderId.substring(0, 8).toUpperCase()} confirmed.\nA receipt has been sent to your email.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/orders/$orderId');
              },
              child: const Text('Track Order'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: const Text('Continue Shopping'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final deliveryFee = _computeDeliveryFee();
    final hasNoSavedAddress = auth.user != null && auth.user!.addresses.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Delivery address
                  _SectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    children: [
                      CustomTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        hint: '+230 5XXX XXXX',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Please enter a phone number' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _line1Ctrl,
                        label: 'Address Line 1',
                        hint: '123 Main Street',
                        prefixIcon: Icons.home_outlined,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Please enter your street address' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _line2Ctrl,
                        label: 'Address Line 2 (optional)',
                        hint: 'Apartment, suite, etc.',
                        prefixIcon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _cityCtrl,
                              label: 'City',
                              hint: 'Port Louis',
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Please enter a city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _postcodeCtrl,
                              label: 'Postcode',
                              hint: '00000',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Please enter a postcode' : null,
                            ),
                          ),
                        ],
                      ),
                      if (hasNoSavedAddress) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _saveAddress = !_saveAddress),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _saveAddress
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _saveAddress
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : const Color(0xFFE8E8E8),
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _saveAddress ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _saveAddress ? AppColors.primary : const Color(0xFFCCCCCC),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _saveAddress
                                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save this address',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'Reuse it next time you check out',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Delivery type
                  _SectionCard(
                    title: 'Delivery Method',
                    icon: Icons.local_shipping_outlined,
                    children: [
                      ..._deliveryTypes.map((d) => RadioListTile<DeliveryTypeModel>(
                            value: d,
                            // ignore: deprecated_member_use
                            groupValue: _selectedDelivery,
                            title: Text(d.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${d.description ?? ''} ${d.estimatedDays != null ? '• ${d.estimatedDays}' : ''}',
                            ),
                            secondary: Text(
                              d.fee == 0 ? 'Free' : 'Rs ${d.fee.toInt()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            // ignore: deprecated_member_use
                            onChanged: (v) =>
                                setState(() => _selectedDelivery = v),
                          )),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment type
                  _SectionCard(
                    title: 'Payment Method',
                    icon: Icons.payment_outlined,
                    children: [
                      ..._paymentTypes.map((p) => RadioListTile<PaymentTypeModel>(
                            value: p,
                            // ignore: deprecated_member_use
                            groupValue: _selectedPayment,
                            title: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: p.description != null
                                ? Text(p.description!)
                                : null,
                            secondary: p.fee > 0
                                ? Text('+Rs ${p.fee.toInt()}',
                                    style: const TextStyle(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w500))
                                : null,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            // ignore: deprecated_member_use
                            onChanged: (v) =>
                                setState(() => _selectedPayment = v),
                          )),
                      if (_selectedPayment?.instructions != null) ...[
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedPayment!.instructions!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Order summary
                  _SectionCard(
                    title: 'Order Summary',
                    icon: Icons.receipt_outlined,
                    children: [
                      ...cart.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.name} x${item.quantity}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  'Rs ${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                      const Divider(),
                      _OrderRow('Subtotal',
                          'Rs ${cart.subtotal.toStringAsFixed(0)}'),
                      if (cart.engravingTotal > 0)
                        _OrderRow('Engraving',
                            'Rs ${cart.engravingTotal.toStringAsFixed(0)}'),
                      if (cart.couponDiscount > 0)
                        _OrderRow('Discount',
                            '-Rs ${cart.couponDiscount.toStringAsFixed(0)}',
                            isGreen: true),
                      _OrderRow(
                        'Delivery',
                        deliveryFee == 0
                            ? 'Free'
                            : 'Rs ${deliveryFee.toStringAsFixed(0)}',
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const Spacer(),
                          Text(
                            'Rs ${cart.calculateTotal(deliveryFee).toStringAsFixed(0)}',
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

                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Place Order',
                    onPressed: () => _placeOrder(deliveryFee),
                    isLoading: _placingOrder,
                    icon: Icons.check_circle_outline,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _OrderRow(this.label, this.value, {this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isGreen ? AppColors.success : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
