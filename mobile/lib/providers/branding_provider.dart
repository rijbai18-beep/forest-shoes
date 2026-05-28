import 'dart:async';
import 'package:flutter/material.dart';
import '../services/branding_service.dart';

class BrandingProvider extends ChangeNotifier {
  String? _logoUrl;
  StreamSubscription<String?>? _sub;

  String? get logoUrl => _logoUrl;

  BrandingProvider() {
    _sub = BrandingService().watchLogoUrl().listen((url) {
      if (_logoUrl != url) {
        _logoUrl = url;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
