import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  File? _pickedImage;
  // Holds the Storage URL optimistically after a successful save so the photo
  // shows immediately without waiting for the Firestore stream to round-trip.
  String? _localPhotoUrl;
  bool _uploadingPhoto = false;

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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return null;
    setState(() => _uploadingPhoto = true);
    try {
      // Path must match Storage rules: users/{uid}/profile/{file}
      final ref = FirebaseStorage.instance
          .ref('users/$uid/profile/avatar.jpg');
      await ref.putFile(_pickedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload photo. Please try again.')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    // Priority: local file > optimistic URL from last save > Firestore URL
    final photoUrl = _pickedImage != null
        ? null
        : (_localPhotoUrl ?? user?.photoUrl);
    final initials =
        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null),
                      child: (_pickedImage == null && photoUrl == null)
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _uploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Photo selected — save to apply',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── User details card ────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Please enter your name' : null,
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
                      subtitle: Text(user?.email ?? ''),
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
              isLoading: auth.isLoading || _uploadingPhoto,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);

                String? newPhotoUrl;
                if (_pickedImage != null && user != null) {
                  newPhotoUrl = await _uploadPhoto(user.uid);
                }

                if (!mounted) return;
                final success = await auth.updateProfile(
                  name: _nameCtrl.text,
                  phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
                  photoUrl: newPhotoUrl,
                );
                if (!mounted) return;
                if (success) {
                  setState(() {
                    _pickedImage = null;
                    if (newPhotoUrl != null) _localPhotoUrl = newPhotoUrl;
                  });
                }
                messenger.showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Profile updated!'
                      : auth.errorMessage ?? 'Could not update profile. Please try again.'),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
