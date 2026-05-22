import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/cache_config.dart';
import '../../config/theme.dart';
import '../../providers/branding_provider.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool onDark;
  const AppLogoWidget({super.key, required this.size, this.onDark = false});

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
        placeholder: (_, __) => _fallback,
        errorWidget: (_, __, ___) => _fallback,
      );
    }
    return _fallback;
  }

  Widget get _fallback {
    final bg = onDark ? Colors.white : AppColors.primary;
    final fg = onDark ? AppColors.primary : Colors.white;
    final radius = size * 0.22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: onDark
            ? null
            : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text(
          'FS',
          style: TextStyle(
            color: fg,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );
  }
}
