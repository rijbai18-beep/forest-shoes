import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared cache manager used by all CachedNetworkImage widgets.
/// 7-day stale period, 300 max objects.
class AppCacheManager extends CacheManager {
  static const _key = 'forestShoesCacheV1';

  static final AppCacheManager _instance = AppCacheManager._();
  factory AppCacheManager() => _instance;

  AppCacheManager._()
      : super(Config(
          _key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 300,
        ));
}
