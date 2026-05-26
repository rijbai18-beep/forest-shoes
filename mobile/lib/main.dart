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

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

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
  bool _wasLoggedIn = false;

  static const _sessionTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // Called on any pointer event while the user is logged in.
  void _onUserActivity() {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, _onSessionExpired);
  }

  Future<void> _onSessionExpired() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    await auth.signOut();
    if (!mounted) return;
    _router.go('/login?timeout=true');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.read<ProductProvider>();

    // Start or clear wishlist stream whenever auth state changes.
    final uid = auth.user?.uid;
    if (uid != null && uid != _lastWishlistUid) {
      _lastWishlistUid = uid;
      products.listenToWishlist(uid);
    } else if (uid == null && _lastWishlistUid != null) {
      _lastWishlistUid = null;
      products.clearWishlist();
    }

    // Start the inactivity timer when user logs in; cancel it on logout.
    if (auth.isLoggedIn && !_wasLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onUserActivity());
    } else if (!auth.isLoggedIn && _wasLoggedIn) {
      _sessionTimer?.cancel();
      _sessionTimer = null;
    }
    _wasLoggedIn = auth.isLoggedIn;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
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
