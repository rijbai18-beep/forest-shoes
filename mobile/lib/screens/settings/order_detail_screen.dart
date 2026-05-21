import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  OrderModel? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await _service.getOrder(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_order == null) return;
    final pdf = pw.Document();
    final order = _order!;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('FOREST SHOES',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('RECEIPT',
                  style: const pw.TextStyle(
                      fontSize: 16, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Order: #${order.id.substring(0, 8).toUpperCase()}'),
          pw.Text('Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}'),
          pw.Text('Status: ${order.statusLabel}'),
          pw.SizedBox(height: 20),
          pw.Text('ITEMS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          ...order.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                          '${item.name} (${item.size}, ${item.color}) x${item.quantity}'),
                    ),
                    pw.Text('Rs ${(item.price * item.quantity).toStringAsFixed(0)}'),
                  ],
                ),
              )),
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Subtotal'),
            pw.Text('Rs ${order.subtotal.toStringAsFixed(0)}'),
          ]),
          if (order.engravingFee > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Engraving'),
              pw.Text('Rs ${order.engravingFee.toStringAsFixed(0)}'),
            ]),
          if (order.couponDiscount > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Discount'),
              pw.Text('-Rs ${order.couponDiscount.toStringAsFixed(0)}'),
            ]),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Delivery'),
            pw.Text('Rs ${order.deliveryFee.toStringAsFixed(0)}'),
          ]),
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text('Rs ${order.total.toStringAsFixed(0)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          ]),
          pw.SizedBox(height: 30),
          pw.Text('Thank you for shopping with Forest Shoes!',
              style: const pw.TextStyle(color: PdfColors.grey600)),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final o = _order!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('#${o.id.substring(0, 8).toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download Receipt',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Status',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  _StatusTimeline(status: o.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items (${o.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...o.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${item.size} • ${item.color} • Qty: ${item.quantity}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                  if (item.engravingText != null)
                                    Text('Engraving: "${item.engravingText}"',
                                        style: const TextStyle(
                                            color: AppColors.primary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('Rs ${(item.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
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
                  _Row('Subtotal', 'Rs ${o.subtotal.toStringAsFixed(0)}'),
                  if (o.engravingFee > 0)
                    _Row('Engraving', 'Rs ${o.engravingFee.toStringAsFixed(0)}'),
                  if (o.couponDiscount > 0)
                    _Row('Discount', '-Rs ${o.couponDiscount.toStringAsFixed(0)}'),
                  _Row('Delivery', 'Rs ${o.deliveryFee.toStringAsFixed(0)}'),
                  const Divider(),
                  _Row('Total', 'Rs ${o.total.toStringAsFixed(0)}',
                      bold: true, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delivery address
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(o.address.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(o.address.phone),
                  Text(o.address.formatted,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Payment
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment & Delivery',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  _Row('Payment', o.paymentType),
                  _Row('Delivery', o.deliveryType),
                  if (o.couponCode != null) _Row('Coupon', o.couponCode!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    ('new', 'Order Placed', Icons.shopping_bag_outlined),
    ('reviewed', 'Payment Reviewed', Icons.verified_outlined),
    ('processing', 'Processing', Icons.precision_manufacturing_outlined),
    ('dispatched', 'Dispatched', Icons.local_shipping_outlined),
    ('delivered', 'Delivered', Icons.check_circle_outline),
  ];

  int get _currentStep {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentStep;
    if (status == 'cancelled') {
      return const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error),
          SizedBox(width: 8),
          Text('Order Cancelled',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      );
    }
    return Column(
      children: _steps.asMap().entries.map((e) {
        final isDone = e.key <= current;
        final isActive = e.key == current;
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                  child: Icon(e.value.$3,
                      size: 16,
                      color: isDone ? Colors.white : AppColors.textHint),
                ),
                if (e.key < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: e.key < current
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              e.value.$2,
              style: TextStyle(
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.normal,
                color: isDone
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
