import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'urgent_review_controller.dart';

class UrgentReviewScreen extends StatelessWidget {
  const UrgentReviewScreen({
    super.key,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.selectedTime,
    required this.totalDuration,
    required this.totalPrice,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic> selectedStaff;
  final String selectedTime;
  final int totalDuration;
  final double totalPrice;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UrgentReviewController(
        shopId: shopId,
        customerName: customerName,
        customerPhone: customerPhone,
        bookingDate: bookingDate,
        selectedServices: selectedServices,
        selectedStaff: selectedStaff,
        selectedTime: selectedTime,
        totalDuration: totalDuration,
        totalPrice: totalPrice,
      ),
      child: const _UrgentReviewView(),
    );
  }
}

class _UrgentReviewView extends StatelessWidget {
  const _UrgentReviewView();

  Future<void> _book(BuildContext context, UrgentReviewController controller) async {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Urgent Booking', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'The time will be checked again by the database before the booking is created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('BOOK NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await controller.createBooking();
    if (!context.mounted) return;

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.check_circle_outline, size: 54, color: primaryColor),
          title: const Text('Booking Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Urgent appointment has been created successfully.', textAlign: TextAlign.center),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(controller.errorMessage ?? 'Unable to create booking.', style: const TextStyle(fontWeight: FontWeight.bold)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<UrgentReviewController>(
        builder: (context, controller, _) {
          if (controller.isLoadingShop) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (controller.errorMessage != null && controller.shopName == 'Shop') {
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
                      onPressed: controller.loadShop,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SummarySection(
                  title: 'Shop',
                  icon: Icons.store_outlined,
                  primaryColor: primaryColor,
                  child: Text(
                    controller.shopName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                _SummarySection(
                  title: 'Customer',
                  icon: Icons.person_outline,
                  primaryColor: primaryColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (controller.customerPhone.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(controller.customerPhone, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SummarySection(
                  title: 'Staff',
                  icon: Icons.badge_outlined,
                  primaryColor: primaryColor,
                  child: Text(
                    controller.selectedStaff['name']?.toString() ?? 'Staff',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _SummarySection(
                  title: 'Date & Time',
                  icon: Icons.calendar_month_outlined,
                  primaryColor: primaryColor,
                  child: Text(
                    '${controller.dateText()}  •  ${controller.timeText()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                _SummarySection(
                  title: 'Selected Services',
                  icon: Icons.content_cut_outlined,
                  primaryColor: primaryColor,
                  child: Column(
                    children: controller.selectedServices
                        .map(
                          (service) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text(service['service_name']?.toString() ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text('₹${_price(service['price'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _TotalRow(label: 'Total Duration', value: '${controller.totalDuration} minutes'),
                        const SizedBox(height: 10),
                        _TotalRow(label: 'Total Price', value: '₹${controller.totalPrice.toStringAsFixed(0)}', bold: true, primaryColor: primaryColor),
                        const SizedBox(height: 10),
                        _TotalRow(label: 'Booking Type', value: 'Urgent', bold: true, valueColor: Colors.orange.shade800),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.isBooking ? null : () => _book(context, controller),
                    child: controller.isBooking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('CONFIRM URGENT BOOKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _price(dynamic value) {
    if (value is num) return value.toStringAsFixed(0);
    return double.tryParse(value?.toString() ?? '')?.toStringAsFixed(0) ?? '0';
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.icon, required this.child, required this.primaryColor});

  final String title;
  final IconData icon;
  final Widget child;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false, this.primaryColor, this.valueColor});

  final String label;
  final String value;
  final bool bold;
  final Color? primaryColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 16 : 14,
            color: valueColor ?? (bold ? primaryColor ?? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }
}
