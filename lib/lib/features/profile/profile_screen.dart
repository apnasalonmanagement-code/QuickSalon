import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/cloudinary_service.dart';
import '../salon/salon_profile_screen.dart';
import '../staff/staff_management_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'profile_controller.dart';
import '../report/report_screen.dart';
import '../../app/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController controller;
  final CloudinaryService cloudinary = const CloudinaryService();
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    controller = ProfileController()..addListener(_refresh)..load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    if (!cloudinary.isConfigured) {
      _message('Cloudinary is not configured.');
      return;
    }

    setState(() => uploading = true);
    try {
      final url = await cloudinary.uploadProfileImage(file);
      if (url != null) {
        final current = controller.profile;
        if (current != null) {
          final ok = await controller.save(
            name: current['name']?.toString() ?? '',
            phone: current['phone']?.toString() ?? '',
            imageUrl: url,
          );
          if (!ok) _message(controller.errorMessage ?? 'Unable to save profile image.');
        }
      }
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _edit() async {
    final profile = controller.profile!;
    final name = TextEditingController(text: profile['name']?.toString() ?? '');
    final phone = TextEditingController(text: profile['phone']?.toString() ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (save == true) {
      final ok = await controller.save(
        name: name.text,
        phone: phone.text,
        imageUrl: profile['profile_image_url']?.toString(),
      );
      if (!ok && mounted) _message(controller.errorMessage ?? 'Unable to update profile.');
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _logout() async {
    await controller.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? _error()
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundImage: _imageProvider(profile['profile_image_url']),
                              child: _hasImage(profile['profile_image_url']) ? null : const Icon(Icons.person, size: 54),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  onPressed: uploading ? null : _pickProfileImage,
                                  icon: uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(profile['name']?.toString() ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _info(Icons.person_outline, 'Name', profile['name']),
                      _info(Icons.phone_outlined, 'Phone', profile['phone']),
                      _info(Icons.badge_outlined, 'Role', profile['role']),
                      _info(Icons.store_outlined, 'Shop', profile['shop_name'] ?? profile['shop_id']),
                      const SizedBox(height: 8),
                      FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Profile')),
                      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())), icon: const Icon(Icons.groups_outlined), label: const Text('Staff Management')),
                      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalonProfileScreen())), icon: const Icon(Icons.store_outlined), label: const Text('Shop Profile')),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportScreen()),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Reports & Dashboard'),
                      ),
                      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())), icon: const Icon(Icons.lock_outline), label: const Text('Change Password')),
                      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())), icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text('Delete Account', style: TextStyle(color: Colors.red))),
                      const SizedBox(height: 8),
                      TextButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
                    ],
                  ),
                ),
    );
  }

  Widget _error() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              Text(controller.errorMessage ?? 'Profile unavailable.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: controller.load, child: const Text('Retry')),
            ],
          ),
        ),
      );

  bool _hasImage(dynamic value) => value != null && value.toString().trim().isNotEmpty;

  ImageProvider? _imageProvider(dynamic value) {
    if (!_hasImage(value)) return null;
    return NetworkImage(value.toString());
  }

  Widget _info(IconData icon, String label, dynamic value) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value == null || value.toString().trim().isEmpty ? 'Not set' : value.toString()),
      );
}
