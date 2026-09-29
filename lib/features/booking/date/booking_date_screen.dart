import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../booking_controller.dart';

class BookingDateScreen extends StatelessWidget {
  const BookingDateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = today.add(const Duration(days: 90));
    final primaryColor = Theme.of(context).primaryColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text(
          '🌸 Choose a date',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the day you want to visit ${controller.selectedShop?.shopName ?? 'the salon'}. ✨',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CalendarDatePicker(
              initialDate: controller.selectedDate ?? today,
              firstDate: today,
              lastDate: lastDate,
              onDateChanged: controller.selectDate,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '💡 Shop/staff holiday and final availability validation are intentionally handled by the existing booking system in later steps.',
            style: TextStyle(fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }
}