import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/service_model.dart';
import 'service_controller.dart';

class EditServiceScreen extends StatefulWidget {
  const EditServiceScreen({super.key, required this.service});
  final ServiceModel service;

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryController;
  late final TextEditingController _serviceController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final ServiceController _controller;

  bool _request = false;
  bool _status = true;
  bool _saving = false;
  bool _replaceImage = false;
  XFile? _selectedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _controller = ServiceController();
    _categoryController = TextEditingController(text: service.categoryName);
    _serviceController = TextEditingController(text: service.serviceName);
    _durationController = TextEditingController(text: service.durationMinutes.toString());
    _priceController = TextEditingController(text: service.price.toStringAsFixed(2));

    _request = service.request;
    _status = service.status;
    _imageUrl = service.imageUrl;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _serviceController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() {
      _selectedImage = file;
      _replaceImage = true;
    });

    final url = await _controller.uploadImage(file);
    if (!mounted) return;

    if (url != null) {
      setState(() => _imageUrl = url);
    } else if (_controller.errorMessage != null) {
      _showMessage(_controller.errorMessage!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (duration == null || duration <= 0 || duration % 15 != 0) {
      _showMessage('Duration must be greater than 0 and a multiple of 15 minutes.');
      return;
    }
    if (price == null || price < 0) return;

    setState(() => _saving = true);

    final result = await _controller.update(
      serviceId: widget.service.id,
      categoryName: _categoryController.text,
      serviceName: _serviceController.text,
      durationMinutes: duration,
      price: price,
      request: _request,
      status: _status,
      imageUrl: _imageUrl,
      replaceImageUrl: _replaceImage,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      Navigator.pop(context, result);
    } else {
      _showMessage(_controller.errorMessage ?? 'Unable to update service.');
    }
  }

  Future<void> _deactivate() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Service?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text('"${widget.service.serviceName}" will no longer be available for new bookings. Existing appointments will not be changed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('KEEP')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final success = await _controller.deactivate(widget.service.id);

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, null);
    } else {
      _showMessage(_controller.errorMessage ?? 'Unable to deactivate service.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Service', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                tooltip: 'Deactivate',
                onPressed: _saving ? null : _deactivate,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _CurrentImageCard(
                    imageUrl: _imageUrl,
                    selectedImage: _selectedImage,
                    uploading: _controller.isUploadingImage,
                    onPick: _pickImage,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      prefixIcon: Icon(Icons.category_outlined, color: primaryColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                    validator: (value) => _required(value, 'Category'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _serviceController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Service Name',
                      prefixIcon: Icon(Icons.content_cut_outlined, color: primaryColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                    validator: (value) => _required(value, 'Service name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      prefixIcon: Icon(Icons.schedule_outlined, color: primaryColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                    validator: (value) {
                      final duration = int.tryParse(value?.trim() ?? '');
                      if (duration == null || duration <= 0) return 'Duration must be greater than 0.';
                      if (duration % 15 != 0) return 'Duration must be a multiple of 15 minutes.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      if (price == null || price < 0) return 'Price must be 0 or greater.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  _RequestSwitch(value: _request, enabled: !_saving, onChanged: (value) => setState(() => _request = value)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile.adaptive(
                      activeColor: primaryColor,
                      title: Text(_status ? 'Service Active' : 'Service Inactive', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Inactive services are hidden from new bookings.'),
                      value: _status,
                      onChanged: _saving ? null : (value) => setState(() => _status = value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _saving || _controller.isUploadingImage ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RequestSwitch extends StatelessWidget {
  const _RequestSwitch({required this.value, required this.enabled, required this.onChanged});
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile.adaptive(
        activeColor: primaryColor,
        title: Text(value ? 'Send Request ON' : 'Send Request OFF', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value ? 'Bookings require management approval.' : 'Bookings can be directly confirmed.'),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _CurrentImageCard extends StatelessWidget {
  const _CurrentImageCard({required this.imageUrl, required this.selectedImage, required this.uploading, required this.onPick});
  final String? imageUrl;
  final XFile? selectedImage;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final provider = imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: provider,
              child: provider == null ? Icon(Icons.image_outlined, size: 32, color: primaryColor) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Image', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(selectedImage?.name ?? 'Current image / optional', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: uploading ? null : onPick,
                    icon: uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_outlined),
                    label: Text(uploading ? 'Uploading...' : 'Change Image', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}