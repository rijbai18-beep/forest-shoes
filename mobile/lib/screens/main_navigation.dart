import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  final _tabs = ['/home', '/shop', '/cart', '/settings'];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final count = await NotificationService().getUnreadCount(auth.user!.uid);
    if (mounted) setState(() => _unreadNotifications = count);
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  int _getCurrentIndex(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final cartCount = context.watch<CartProvider>().itemCount;
    _currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Shop',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart_rounded,
                  label: 'Cart',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                  badge: cartCount > 0 ? cartCount.toString() : null,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                  badge: _unreadNotifications > 0
                      ? _unreadNotifications.toString()
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge != null
                ? badges.Badge(
                    badgeContent: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                      size: 26,
                    ),
                  )
                : Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                    size: 26,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
