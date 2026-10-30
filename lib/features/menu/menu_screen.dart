import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import 'add_category/add_category_screen.dart';
import 'service/edit_service_screen.dart';
import 'menu_controller.dart';
import 'widgets/category_item.dart';
import 'widgets/service_item.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final SalonMenuController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SalonMenuController();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    await _controller.load();
    if (!mounted) return;
    _controller.startRealtime();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_controller.isLoading) return;

    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddCategoryScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _controller.load();
      if (mounted) setState(() {});
    }
  }

  Future<void> _renameCategory(String category) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final TextEditingController textController = TextEditingController(text: category);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          title: Text('Rename Category', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category name is required.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, textController.text.trim());
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    textController.dispose();
    if (!mounted) return;

    if (newName == null || newName.trim().isEmpty || newName.trim() == category.trim()) {
      return;
    }

    final bool success = await _controller.renameCategory(
      oldName: category,
      newName: newName.trim(),
    );

    if (!mounted) return;
    setState(() {});

    if (!success) {
      _showMessage(_controller.errorMessage ?? 'Unable to rename category.');
    }
  }

  Future<void> _showCategoryActions(String category) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final String? action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: primaryColor),
                  title: const Text('Rename Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(sheetContext, 'rename'),
                ),
                ListTile(
                  leading: Icon(Icons.add_outlined, color: primaryColor),
                  title: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(sheetContext, 'add'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'rename') await _renameCategory(category);
    if (action == 'add') await _addServiceToCategory(category);
  }

  Future<void> _addServiceToCategory(String category) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddServiceDialog(
        controller: _controller,
        categoryName: category,
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editService(ServiceModel service) async {
    final result = await Navigator.of(context).push<ServiceModel?>(
      MaterialPageRoute(
        builder: (_) => EditServiceScreen(service: service),
      ),
    );

    if (!mounted) return;

    if (result != null || _controller.errorMessage == null) {
      await _controller.load();
    }

    if (result == null && _controller.errorMessage != null) {
      _showMessage(_controller.errorMessage!);
    }

    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _controller.isLoading
                    ? null
                    : () async {
                        await _controller.load();
                        if (mounted) setState(() {});
                      },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            onPressed: _controller.isLoading ? null : _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_controller.isLoading && _controller.services.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_controller.errorMessage != null && _controller.services.isEmpty) {
      return _ErrorState(
        message: _controller.errorMessage!,
        onRetry: () async {
          await _controller.load();
          if (mounted) setState(() {});
        },
      );
    }

    if (_controller.services.isEmpty) {
      return _EmptyMenuState(onAddCategory: _addCategory);
    }

    final Map<String, List<dynamic>> groups = _controller.groupedServices;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async => await _controller.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (_controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                content: Text(_controller.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                actions: [
                  TextButton(
                    onPressed: () async => await _controller.load(),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          for (final category in _controller.categories)
            CategoryItem(
              categoryName: category,
              serviceCount: groups[category]!.length,
              onRename: () => _showCategoryActions(category),
              child: Column(
                children: [
                  for (final service in groups[category]!)
                    ServiceItem(
                      service: service,
                      onTap: () => _editService(service),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: primaryColor),
                      onPressed: () => _addServiceToCategory(category),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState({required this.onAddCategory});
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No active services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Create a category with its first service to start your menu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
              ),
              onPressed: onAddCategory,
              icon: const Icon(Icons.add),
              label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: onRetry,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceDialog extends StatefulWidget {
  const _AddServiceDialog({required this.controller, required this.categoryName});
  final SalonMenuController controller;
  final String categoryName;

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');
  final TextEditingController _priceController = TextEditingController(text: '0');

  bool _request = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final int? duration = int.tryParse(_durationController.text.trim());
    final double? price = double.tryParse(_priceController.text.trim());

    if (duration == null || duration <= 0 || duration % 15 != 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            content: Text('Duration must be a multiple of 15 minutes.'),
          ),
        );
      }
      return;
    }

    if (price == null || price < 0) return;

    setState(() => _saving = true);

    final bool success = await widget.controller.addService(
      categoryName: widget.categoryName,
      serviceName: _nameController.text.trim(),
      durationMinutes: duration,
      price: price,
      request: _request,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        content: Text(widget.controller.errorMessage ?? 'Unable to add service.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      title: Text('Add Service to ${widget.categoryName}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Service name is required.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                validator: (value) {
                  final int? duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration <= 0) return 'Enter a valid duration.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                validator: (value) {
                  final double? price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price < 0) return 'Enter a valid price.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                title: const Text('Request required', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _request,
                onChanged: _saving ? null : (value) => setState(() => _request = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primaryColor),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('ADD'),
        ),
      ],
    );
  }
}