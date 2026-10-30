import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/cloudinary_service.dart';
import 'staff_controller.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController();
  final _image = TextEditingController();
  final _controller = StaffController();
  final _cloudinary = const CloudinaryService();
  bool _status = true;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _role.dispose();
    _image.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    if (!_cloudinary.isConfigured) {
      _message('Cloudinary is not configured. You can enter an image URL manually.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final url = await _cloudinary.uploadStaffImage(file);
      if (url != null) _image.text = url;
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await _controller.add(
      name: _name.text,
      phone: _phone.text,
      role: _role.text,
      imageUrl: _image.text,
      status: _status,
    );
    if (mounted) setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(_controller.errorMessage ?? 'Unable to add staff.');
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                prefixIcon: Icon(Icons.person_outline, color: primaryColor),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Staff name is required.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (value.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a valid phone number.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Role',
                hintText: 'Senior Stylist',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                prefixIcon: Icon(Icons.badge_outlined, color: primaryColor),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Staff role is required.' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _image,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                      prefixIcon: Icon(Icons.image_outlined, color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _uploading ? null : _pickImage,
                  icon: _uploading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: Icon(Icons.verified_user_outlined, color: primaryColor),
                title: const Text('Staff active', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _status,
                onChanged: (value) => setState(() => _status = value),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving || _uploading ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}


