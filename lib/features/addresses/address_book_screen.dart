import 'package:flutter/material.dart';

import '../../models/user_address_model.dart';
import '../../repositories/user_address_repository.dart';
import 'map_location_picker_screen.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({
    super.key,
    this.onAddressSelected,
  });

  final ValueChanged<UserAddressModel>? onAddressSelected;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final UserAddressRepository _repository = UserAddressRepository();
  List<UserAddressModel> _addresses = <UserAddressModel>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses = await _repository.loadAddresses();
      if (!mounted) return;
      setState(() => _addresses = addresses);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrEditAddress({UserAddressModel? existing}) async {
    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLatitude: existing?.latitude,
          initialLongitude: existing?.longitude,
          initialAddress: existing?.fullAddress,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final labelController = TextEditingController(text: existing?.label ?? 'Home');
    final landmarkController = TextEditingController(text: existing?.landmark ?? '');
    bool makeDefault = existing?.isDefault ?? _addresses.isEmpty;
    String label = existing?.label ?? 'Home';

    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Save address' : 'Update address'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.fullAddress,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: label,
                        decoration: const InputDecoration(labelText: 'Address label'),
                        items: const [
                          DropdownMenuItem(value: 'Home', child: Text('Home')),
                          DropdownMenuItem(value: 'Work', child: Text('Work')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => label = value);
                            labelController.text = value;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: landmarkController,
                        decoration: const InputDecoration(
                          labelText: 'Landmark (optional)',
                          hintText: 'Near school, building, etc.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: makeDefault,
                        title: const Text('Set as default address'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setDialogState(() => makeDefault = value ?? false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final landmarkValue = landmarkController.text;
    labelController.dispose();
    landmarkController.dispose();

    if (shouldSave != true || !mounted) return;

    try {
      await _repository.saveAddress(
        id: existing?.id,
        label: label,
        fullAddress: result.fullAddress,
        landmark: landmarkValue,
        latitude: result.latitude,
        longitude: result.longitude,
        isDefault: makeDefault,
      );
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteAddress(UserAddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove ${address.label} from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteAddress(address.id);
      await _loadAddresses();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _setDefault(UserAddressModel address) async {
    try {
      await _repository.setDefaultAddress(address.id);
      await _loadAddresses();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _selectAddress(UserAddressModel address) {
    widget.onAddressSelected?.call(address);
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved addresses'),
        actions: [
          IconButton(
            tooltip: 'Refresh addresses',
            onPressed: _isLoading ? null : _loadAddresses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditAddress(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add address'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadAddresses,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 58),
                            const SizedBox(height: 12),
                            Text(
                              'No saved addresses yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add an address by searching for a place or moving the pin on the map.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _addOrEditAddress(),
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('Add your first address'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    child: Icon(
                                      address.label == 'Home'
                                          ? Icons.home_outlined
                                          : address.label == 'Work'
                                              ? Icons.work_outline
                                              : Icons.location_on_outlined,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          address.label,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        const Chip(
                                          label: Text('Default'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      [
                                        address.fullAddress,
                                        if ((address.landmark ?? '').trim().isNotEmpty)
                                          'Landmark: ${address.landmark}',
                                      ].join('\n'),
                                    ),
                                  ),
                                  onTap: () => _selectAddress(address),
                                ),
                                const Divider(),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _addOrEditAddress(existing: address),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Edit'),
                                    ),
                                    if (!address.isDefault)
                                      TextButton(
                                        onPressed: () => _setDefault(address),
                                        child: const Text('Make default'),
                                      ),
                                    IconButton(
                                      tooltip: 'Delete address',
                                      onPressed: () => _deleteAddress(address),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                    FilledButton.tonal(
                                      onPressed: () => _selectAddress(address),
                                      child: const Text('Use this'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
