import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    // Green header height (safe area + title row + breathing room)
    const double greenBodyHeight = 120.0;
    // How far the user card bleeds below the green into gray
    const double cardOverhang = 44.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Green header + user card overlap ──────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: topPad + greenBodyHeight + cardOverhang,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Green background (only the upper portion)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topPad + greenBodyHeight,
                    child: Container(
                      color: AppColors.primary,
                      child: Stack(
                        children: [
                          // Subtle dot decorations
                          ...List.generate(6, (i) {
                            const positions = [
                              [0.12, 0.3], [0.7, 0.15], [0.85, 0.6],
                              [0.3, 0.75], [0.55, 0.2], [0.2, 0.85],
                            ];
                            return Positioned(
                              left: MediaQuery.of(context).size.width *
                                  positions[i][0],
                              top: (topPad + greenBodyHeight) * positions[i][1],
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Title row inside the green area
                  Positioned(
                    top: topPad + 22,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        const Text(
                          'My Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User card — straddling the green/gray boundary
                  Positioned(
                    bottom: 0,
                    left: 16,
                    right: 16,
                    child: auth.isLoggedIn
                        ? _UserCard(
                            name: auth.user!.name,
                            email: auth.user!.email,
                            onEdit: () => context.push('/profile'),
                          )
                        : _GuestCard(
                            onLogin: () => context.push('/login'),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable menu content ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── General section ────────────────────────────────────
                  const _SectionLabel('General'),
                  const SizedBox(height: 12),

                  if (auth.isLoggedIn) ...[
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transaction',
                      onTap: () => context.push('/orders'),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      onTap: () => context.push('/wishlist'),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Saved Address',
                      onTap: () => context.push('/addresses'),
                    ),
                    const SizedBox(height: 10),
                  ],

                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notification',
                    onTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 10),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Security',
                    onTap: () => context.push('/content/dataPrivacy'),
                  ),

                  // ── Help section ───────────────────────────────────────
                  const SizedBox(height: 28),
                  const _SectionLabel('Help'),
                  const SizedBox(height: 12),

                  if (auth.isLoggedIn) ...[
                    _MenuItem(
                      icon: Icons.support_agent_outlined,
                      label: 'Customer Support',
                      onTap: () => context.push('/support'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => context.push('/content/terms'),
                  ),
                  const SizedBox(height: 10),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => context.push('/content/privacy'),
                  ),
                  const SizedBox(height: 10),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Forest Shoes',
                    onTap: () => context.push('/content/about'),
                  ),

                  // ── Logout ─────────────────────────────────────────────
                  if (auth.isLoggedIn) ...[
                    const SizedBox(height: 28),
                    const _SectionLabel('Account'),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      onTap: () => _confirmLogout(context, auth),
                      labelColor: AppColors.error,
                      iconColor: AppColors.error,
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'Forest Shoes v1.0.0',
                      style:
                          TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ── User card (logged in) ─────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;

  const _UserCard(
      {required this.name, required this.email, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Edit icon
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit_square,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest card (not logged in) ────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest User',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: 3),
                Text('Sign in to your account',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: onLogin,
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Individual menu item (white card) ─────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? AppColors.textPrimary;
    final lColor = labelColor ?? AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: lColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: labelColor ?? AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
