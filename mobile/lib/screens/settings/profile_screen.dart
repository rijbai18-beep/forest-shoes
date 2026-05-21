import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      auth.user?.name[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined,
                          color: AppColors.primary),
                      title: const Text('Email'),
                      subtitle: Text(auth.user?.email ?? ''),
                      trailing: const Icon(Icons.lock_outline,
                          color: AppColors.textHint, size: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Save Changes',
              isLoading: auth.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                final success = await auth.updateProfile(
                  name: _nameCtrl.text,
                  phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
                );
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(
                      success ? 'Profile updated!' : auth.errorMessage ?? 'Error'),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
