import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../staff/urgent_staff_screen.dart';
import 'urgent_services_controller.dart';

class UrgentServicesScreen extends StatelessWidget {
  const UrgentServicesScreen({
    super.key,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UrgentServicesController(shopId: shopId),
      child: _UrgentServicesView(
        shopId: shopId,
        customerName: customerName,
        customerPhone: customerPhone,
        bookingDate: bookingDate,
      ),
    );
  }
}

class _UrgentServicesView extends StatelessWidget {
  const _UrgentServicesView({
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;

  void _continue(BuildContext context, UrgentServicesController controller) {
    if (controller.selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Please select at least one service.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrgentStaffScreen(
          shopId: shopId,
          customerName: customerName,
          customerPhone: customerPhone,
          bookingDate: bookingDate,
          selectedServices: controller.selectedServices,
          totalDuration: controller.totalDuration,
          totalPrice: controller.totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Services', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<UrgentServicesController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: controller.loadServices,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.services.isEmpty) {
            return const Center(child: Text('No active services found for this shop.', style: TextStyle(fontWeight: FontWeight.bold)));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    Text(
                      'Select one or more services',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    for (final category in controller.categories) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      ...controller.servicesForCategory(category).map(
                        (service) => _ServiceTile(
                          service: service,
                          selected: controller.isSelected(service['id'].toString()),
                          onTap: () => controller.toggleService(service['id'].toString()),
                          primaryColor: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _BottomSummary(
                duration: controller.totalDuration,
                price: controller.totalPrice,
                enabled: controller.selectedIds.isNotEmpty,
                onContinue: () => _continue(context, controller),
                primaryColor: primaryColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.selected, required this.onTap, required this.primaryColor});

  final Map<String, dynamic> service;
  final bool selected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final duration = service['duration_minutes']?.toString() ?? '0';
    final price = _price(service['price']);

    return Card(
      elevation: selected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? primaryColor : Colors.transparent, width: 2),
      ),
      child: CheckboxListTile(
        activeColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        value: selected,
        onChanged: (_) => onTap(),
        title: Text(service['service_name']?.toString() ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$duration min  •  ₹$price', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        secondary: service['request'] == true
            ? Tooltip(
                message: 'This service normally requires a request',
                child: Icon(Icons.info_outline, color: primaryColor),
              )
            : null,
      ),
    );
  }

  String _price(dynamic value) {
    if (value is num) return value.toStringAsFixed(0);
    return double.tryParse(value?.toString() ?? '')?.toStringAsFixed(0) ?? '0';
  }
}

class _BottomSummary extends StatelessWidget {
  const _BottomSummary({required this.duration, required this.price, required this.enabled, required this.onContinue, required this.primaryColor});

  final int duration;
  final double price;
  final bool enabled;
  final VoidCallback onContinue;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$duration min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(140, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: enabled ? onContinue : null,
                child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
