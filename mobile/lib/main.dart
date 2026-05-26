import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/branding_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'services/notification_service.dart';
import 'services/audit_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  // Capture Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AuditService.instance.logError(
      details.exception, details.stack, context: 'flutter_framework',
    );
  };

  // Capture uncaught async/platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AuditService.instance.logError(error, stack, context: 'platform_error');
    return true;
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ForestShoesApp());
}

class ForestShoesApp extends StatelessWidget {
  const ForestShoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router;
  String? _lastWishlistUid;

  Timer? _sessionTimer;
  Timer? _warnTimer;
  bool _wasLoggedIn = false;
  bool _warningShown = false;

  static const _sessionTimeout = Duration(minutes: 5);
  static const _warnOffset = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _warnTimer?.cancel();
    super.dispose();
  }

  void _onUserActivity() {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    _resetTimers();
  }

  void _resetTimers() {
    _sessionTimer?.cancel();
    _warnTimer?.cancel();
    _warningShown = false;
    _warnTimer = Timer(_sessionTimeout - _warnOffset, _onSessionWarning);
    _sessionTimer = Timer(_sessionTimeout, _onSessionExpired);
  }

  void _onSessionWarning() {
    if (!mounted) return;
    _warningShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Expiring'),
        content: const Text(
          'You will be automatically logged out in 1 minute due to inactivity.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _warningShown = false;
              _resetTimers();
            },
            child: const Text('Stay Logged In'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSessionExpired() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    if (_warningShown) {
      _warningShown = false;
      Navigator.of(context, rootNavigator: true).maybePop();
    }
    await auth.signOut();
    if (!mounted) return;
    _router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.read<ProductProvider>();

    final uid = auth.user?.uid;
    if (uid != null && uid != _lastWishlistUid) {
      _lastWishlistUid = uid;
      products.listenToWishlist(uid);
    } else if (uid == null && _lastWishlistUid != null) {
      _lastWishlistUid = null;
      products.clearWishlist();
    }

    if (auth.isLoggedIn && !_wasLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onUserActivity());
    } else if (!auth.isLoggedIn && _wasLoggedIn) {
      _sessionTimer?.cancel();
      _warnTimer?.cancel();
      _sessionTimer = null;
      _warnTimer = null;
    }
    _wasLoggedIn = auth.isLoggedIn;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      child: OverlaySupport.global(
        child: MaterialApp.router(
          title: 'Forest Shoes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
