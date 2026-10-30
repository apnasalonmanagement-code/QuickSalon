import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../review/urgent_review_screen.dart';
import 'urgent_time_controller.dart';

class UrgentTimeScreen extends StatelessWidget {
  const UrgentTimeScreen({
    super.key,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.totalDuration,
    required this.totalPrice,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic> selectedStaff;
  final int totalDuration;
  final double totalPrice;

  String _slotEnd(String startTime) {
    final parts = startTime.split(':');
    if (parts.length < 2) return startTime;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return startTime;

    final start = Duration(hours: hour, minutes: minute);
    final end = start + Duration(minutes: totalDuration);
    final endHour = end.inHours % 24;
    final endMinute = end.inMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  String _slotRange(
    UrgentTimeController controller,
    String start,
  ) {
    return '${controller.displayTime(start)} - ${controller.displayTime(_slotEnd(start))}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UrgentTimeController(
        shopId: shopId,
        staffId: selectedStaff['id'].toString(),
        bookingDate: bookingDate,
        durationMinutes: totalDuration,
      ),
      child: _UrgentTimeView(
        shopId: shopId,
        customerName: customerName,
        customerPhone: customerPhone,
        bookingDate: bookingDate,
        selectedServices: selectedServices,
        selectedStaff: selectedStaff,
        totalDuration: totalDuration,
        totalPrice: totalPrice,
      ),
    );
  }
}

class _UrgentTimeView extends StatelessWidget {
  const _UrgentTimeView({
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.totalDuration,
    required this.totalPrice,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic> selectedStaff;
  final int totalDuration;
  final double totalPrice;

  String _slotEnd(String startTime) {
    final parts = startTime.split(':');
    if (parts.length < 2) return startTime;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return startTime;

    final start = Duration(hours: hour, minutes: minute);
    final end = start + Duration(minutes: totalDuration);
    final endHour = end.inHours % 24;
    final endMinute = end.inMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  String _slotRange(
    UrgentTimeController controller,
    String start,
  ) {
    return '${controller.displayTime(start)} - ${controller.displayTime(_slotEnd(start))}';
  }

  void _continue(
    BuildContext context,
    UrgentTimeController controller,
  ) {
    final time = controller.selectedTime;
    if (time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Please select a time.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrgentReviewScreen(
          shopId: shopId,
          customerName: customerName,
          customerPhone: customerPhone,
          bookingDate: bookingDate,
          selectedServices: selectedServices,
          selectedStaff: selectedStaff,
          selectedTime: time,
          totalDuration: totalDuration,
          totalPrice: totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Time', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<UrgentTimeController>(
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: controller.loadTimes,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.times.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No available starting times for this staff member on the selected date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: controller.times.length,
                  itemBuilder: (context, index) {
                    final time = controller.times[index];
                    final selected = controller.selectedTime == time;

                    return OutlinedButton(
                      onPressed: () => controller.selectTime(time),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: selected ? primaryColor : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                        backgroundColor: selected
                            ? primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _slotRange(controller, time),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? primaryColor : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Material(
                elevation: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.selectedTime == null
                            ? null
                            : () => _continue(context, controller),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('REVIEW BOOKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
