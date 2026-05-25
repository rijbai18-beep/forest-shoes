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

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
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

    return OverlaySupport.global(
      child: MaterialApp.router(
        title: 'Forest Shoes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
