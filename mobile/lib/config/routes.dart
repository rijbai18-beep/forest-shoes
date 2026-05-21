import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/home/home_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/order_history_screen.dart';
import '../screens/settings/order_detail_screen.dart';
import '../screens/settings/content_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/support/ticket_detail_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const shop = '/shop';
  static const productDetail = '/product/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const settings = '/settings';
  static const profile = '/profile';
  static const orderHistory = '/orders';
  static const orderDetail = '/orders/:id';
  static const content = '/content/:type';
  static const notifications = '/notifications';
  static const wishlist = '/wishlist';
  static const support = '/support';
  static const ticketDetail = '/support/:id';
}

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.isLoggedIn;
      final isOnAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!auth.isInitialized) return null;
      if (!isLoggedIn && !isOnAuthRoute && state.matchedLocation != AppRoutes.splash) {
        if (state.matchedLocation == AppRoutes.checkout) return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.shop,
            builder: (context, state) => ShopScreen(
              categoryId: state.uri.queryParameters['category'],
              gender: state.uri.queryParameters['gender'],
            ),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/content/:type',
        builder: (context, state) =>
            ContentScreen(contentType: state.pathParameters['type']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
