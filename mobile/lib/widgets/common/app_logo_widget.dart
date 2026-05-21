import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../config/cache_config.dart';
import '../../providers/branding_provider.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  const AppLogoWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final logoUrl = context.watch<BrandingProvider>().logoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        cacheManager: AppCacheManager(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => _localSvg,
        errorWidget: (_, __, ___) => _localSvg,
      );
    }
    return _localSvg;
  }

  Widget get _localSvg => SvgPicture.asset(
        'assets/images/logo_icon.svg',
        width: size,
        height: size,
      );
}
