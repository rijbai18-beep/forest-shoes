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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: auth.isLoggedIn
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      auth.user!.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auth.user!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          auth.user!.email,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withValues(alpha: 0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.white),
                                    onPressed: () =>
                                        context.push('/profile'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: () => context.push('/login'),
                                child: const Text('Sign In'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Account section
                  if (auth.isLoggedIn) ...[
                    _SettingsSection(
                      title: 'Account',
                      items: [
                        _SettingsTile(
                          icon: Icons.person_outline,
                          title: 'Profile',
                          subtitle: 'Edit your personal details',
                          onTap: () => context.push('/profile'),
                        ),
                        _SettingsTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Order History',
                          subtitle: 'View and track your orders',
                          onTap: () => context.push('/orders'),
                        ),
                        _SettingsTile(
                          icon: Icons.favorite_border_rounded,
                          title: 'Wishlist',
                          subtitle: 'Your saved products',
                          onTap: () => context.push('/wishlist'),
                        ),
                        _SettingsTile(
                          icon: Icons.support_agent_outlined,
                          title: 'Customer Support',
                          subtitle: 'Get help with your orders',
                          onTap: () => context.push('/support'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notifications
                  _SettingsSection(
                    title: 'Notifications',
                    items: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'View all notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info section
                  _SettingsSection(
                    title: 'Information',
                    items: [
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        onTap: () => context.push('/content/terms'),
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => context.push('/content/privacy'),
                      ),
                      _SettingsTile(
                        icon: Icons.security_outlined,
                        title: 'Data Privacy',
                        onTap: () => context.push('/content/dataPrivacy'),
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About Forest Shoes',
                        onTap: () => context.push('/content/about'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  if (auth.isLoggedIn)
                    Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.error),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: AppColors.textHint),
                        onTap: () => _confirmLogout(context, auth),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // App version
                  const Text(
                    'Forest Shoes v1.0.0',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < items.length - 1)
                          const Divider(
                              height: 1, indent: 56, endIndent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
