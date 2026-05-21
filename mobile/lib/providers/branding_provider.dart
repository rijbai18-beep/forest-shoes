import 'package:flutter/material.dart';
import '../services/branding_service.dart';

class BrandingProvider extends ChangeNotifier {
  String? _logoUrl;

  String? get logoUrl => _logoUrl;

  BrandingProvider() {
    BrandingService().watchLogoUrl().listen((url) {
      if (_logoUrl != url) {
        _logoUrl = url;
        notifyListeners();
      }
    });
  }
}
