import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/service_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/staff_model.dart';
import 'booking_review_controller.dart';

class BookingReviewScreen extends StatelessWidget {
  const BookingReviewScreen({
    super.key,
    required this.shop,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.selectedTime,
    required this.onBookingSuccess,
  });

  final ShopModel shop;
  final DateTime bookingDate;
  final List<ServiceModel> selectedServices;
  final StaffModel selectedStaff;
  final String selectedTime;
  final VoidCallback onBookingSuccess;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingReviewController(
        shop: shop,
        bookingDate: bookingDate,
        selectedServices: selectedServices,
        selectedStaff: selectedStaff,
        selectedTime: selectedTime,
      ),
      child: _BookingReviewView(onBookingSuccess: onBookingSuccess),
    );
  }
}

class _BookingReviewView extends StatelessWidget {
  const _BookingReviewView({required this.onBookingSuccess});

  final VoidCallback onBookingSuccess;

  Future<void> _confirm(
    BuildContext context,
    BookingReviewController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🌸 Confirm booking? 🌸'),
        content: Text(
          controller.requiresRequestApproval
              ? 'This booking contains a service that requires approval. It will be submitted as a request.'
              : 'This booking will be confirmed if the selected time is still available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm ✨'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await controller.createBooking();
    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Unable to create booking.'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final actualStatus = controller.createdBookingStatus;
    final isPending = actualStatus == 'pending';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
        title: Text(
          isPending
              ? '🌸 Booking Request Submitted 🌸'
              : '🌸 Booking Confirmed 🌸',
        ),
        content: Text(
          isPending
              ? 'Your booking request was submitted successfully. You can track its status in My Appointments.'
              : 'Your appointment was confirmed successfully. You can view it in My Appointments.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('MY APPOINTMENTS'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    onBookingSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Consumer<BookingReviewController>(
      builder: (context, controller, _) {
        if (controller.isLoadingCustomer && controller.customerName == 'Customer') {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _Section(
                title: 'SHOP',
                icon: Icons.store_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.shop.shopName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(controller.shop.city.isEmpty ? 'City not available' : controller.shop.city),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'CUSTOMER',
                icon: Icons.person_outline,
                child: Text(controller.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              _Section(
                title: 'STAFF',
                icon: Icons.badge_outlined,
                child: Text(controller.selectedStaff.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'DATE & TIME',
                icon: Icons.calendar_month_outlined,
                child: Text(
                  '${controller.dateText()}  •  ${controller.displayTime(controller.selectedTime)} → ${controller.displayTime(controller.endTime)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'SERVICES',
                icon: Icons.content_cut_outlined,
                child: Column(
                  children: controller.selectedServices
                      .map((service) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service.serviceName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '⏱️ ${service.durationMinutes} min',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text('₹${service.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TotalRow(
                        label: 'Total Duration',
                        value: '${controller.totalDuration} minutes',
                      ),
                      const SizedBox(height: 10),
                      _TotalRow(
                        label: 'Total Price',
                        value: '₹${controller.totalPrice.toStringAsFixed(2)}',
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      const _TotalRow(label: 'Booking Type', value: 'Normal'),
                      const SizedBox(height: 10),
                      _TotalRow(
                        label: 'Request Status',
                        value: controller.requiresRequestApproval
                            ? 'Approval required ⚠️'
                            : 'Direct confirmation ✅',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: controller.isBooking
                        ? null
                        : () => _confirm(context, controller),
                    child: controller.isBooking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            controller.requiresRequestApproval
                                ? 'SUBMIT BOOKING REQUEST 🌸'
                                : 'CONFIRM BOOKING 🌸',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryColor)),
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
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 15) : null;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}