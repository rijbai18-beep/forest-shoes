import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';

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
        _content = data['content'] ?? 'No content available.';
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
