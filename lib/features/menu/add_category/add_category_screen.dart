import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'category_controller.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _serviceController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _priceController = TextEditingController(text: '0');
  bool _request = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _serviceController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save(CategoryController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.createCategoryWithFirstService(
      categoryName: _categoryController.text,
      serviceName: _serviceController.text,
      durationMinutes: int.parse(_durationController.text.trim()),
      price: double.parse(_priceController.text.trim()),
      request: _request,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(controller.errorMessage ?? 'Unable to create category.'),
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

    return ChangeNotifierProvider(
      create: (_) => CategoryController(),
      child: Consumer<CategoryController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold))),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'A category organizes your salon services menu together.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
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
                      validator: (value) => _required(value, 'Category name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _serviceController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'First Service Name',
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
                        if (duration == null || duration <= 0) return 'Enter a valid duration.';
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
                        if (price == null || price < 0) return 'Enter a valid price.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile.adaptive(
                        activeColor: primaryColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: const Text('Send request for this service', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Customer bookings become pending when required.'),
                        value: _request,
                        onChanged: controller.isLoading ? null : (value) => setState(() => _request = value),
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
                        onPressed: controller.isLoading ? null : () => _save(controller),
                        child: controller.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('CREATE CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



