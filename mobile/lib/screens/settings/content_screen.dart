import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';

// Template text shown when the admin has not yet saved content for a section.
const _kTemplates = {
  'terms': '''Terms & Conditions

Last updated: January 2025

1. ACCEPTANCE OF TERMS
By accessing or using the Forest Shoes mobile application, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our services.

2. USE OF THE APP
You must be at least 18 years old to place orders. You agree to provide accurate information during registration and checkout. Forest Shoes reserves the right to cancel orders at its discretion.

3. PRODUCTS & PRICING
All prices are displayed in Mauritian Rupees (Rs) and are inclusive of applicable taxes. We reserve the right to modify prices without prior notice. Product images are for illustrative purposes only.

4. ORDERS & PAYMENT
Orders are confirmed upon receipt of payment. We accept cash on delivery and bank transfers. Forest Shoes is not responsible for delays caused by payment providers.

5. DELIVERY
Delivery timelines are estimates only. We are not liable for delays caused by courier services or unforeseen circumstances.

6. RETURNS & REFUNDS
Items may be returned within 7 days of delivery in original, unused condition. Refunds are processed within 5–7 business days.

7. INTELLECTUAL PROPERTY
All content on this app, including logos and images, is the property of Forest Shoes and may not be reproduced without written permission.

8. LIMITATION OF LIABILITY
Forest Shoes shall not be liable for any indirect or consequential damages arising from the use of our services.

9. CONTACT
For queries, contact us at support@forestshoes.mu''',

  'privacy': '''Privacy Policy

Last updated: January 2025

1. INFORMATION WE COLLECT
We collect personal information you provide directly, such as your name, email address, phone number, and delivery address. We also collect usage data to improve the app experience.

2. HOW WE USE YOUR INFORMATION
- To process and fulfil your orders
- To send order confirmations and updates
- To provide customer support
- To send promotional notifications (with your consent)

3. SHARING YOUR INFORMATION
We do not sell your personal data. We share information only with service providers necessary to operate our services (e.g., delivery partners), and only to the extent required.

4. DATA RETENTION
We retain your personal data as long as your account is active or as required by law.

5. YOUR RIGHTS
You have the right to access, correct, or delete your personal data at any time by contacting us.

6. SECURITY
We use industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure.

7. COOKIES
The app does not use cookies. Firebase services may collect anonymised analytics data.

8. CONTACT
For privacy-related requests, contact: support@forestshoes.mu''',

  'dataPrivacy': '''Data Privacy Statement

Forest Shoes is committed to protecting your personal data in accordance with applicable data protection laws.

DATA CONTROLLER
Forest Shoes (Mauritius)
Email: support@forestshoes.mu

DATA WE PROCESS
- Name, email, phone number
- Delivery address
- Order history
- Device and usage data (anonymised)

LEGAL BASIS FOR PROCESSING
We process your data on the basis of contract performance (to fulfil your orders) and legitimate interests (to improve our services).

YOUR RIGHTS UNDER GDPR / LOCAL LAW
- Right to access your data
- Right to rectification
- Right to erasure ("right to be forgotten")
- Right to restrict processing
- Right to data portability
- Right to object

To exercise any of these rights, contact us at support@forestshoes.mu. We will respond within 30 days.

DATA TRANSFERS
Your data is stored on Firebase (Google Cloud) servers, which comply with international data protection standards.

CONTACT OUR DATA OFFICER
support@forestshoes.mu''',

  'about': '''About Forest Shoes

Welcome to Forest Shoes — your destination for premium footwear in Mauritius.

OUR STORY
Founded in Mauritius, Forest Shoes was born from a passion for quality footwear and exceptional customer service. We believe everyone deserves to walk in style and comfort.

OUR PRODUCTS
We curate a wide selection of shoes for men, women, and children — from casual everyday wear to formal occasion footwear. Every product is carefully selected for quality and style.

OUR COMMITMENT
✓ Authentic, quality products
✓ Fast island-wide delivery
✓ Hassle-free returns
✓ Dedicated customer support

CONTACT US
Email: support@forestshoes.mu
Phone: +230 5XXX XXXX
Follow us on social media @forestshoes.mu

Thank you for shopping with us!''',
};

class ContentScreen extends StatefulWidget {
  final String contentType;
  const ContentScreen({super.key, required this.contentType});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String _content = '';
  bool _loading = true;

  String get _title {
    switch (widget.contentType) {
      case 'terms':
        return 'Terms & Conditions';
      case 'privacy':
        return 'Privacy Policy';
      case 'dataPrivacy':
        return 'Data Privacy';
      case 'about':
        return 'About Forest Shoes';
      default:
        return 'Information';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final data = await OrderService().getContent(widget.contentType);
    if (mounted) {
      setState(() {
        // Admin panel saves to field 'body'; fall back to template text.
        _content = (data['body'] as String?)?.trim().isNotEmpty == true
            ? data['body'] as String
            : _kTemplates[widget.contentType] ?? 'No content available.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
