import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../booking_controller.dart';
import 'booking_time_controller.dart';

class BookingTimeScreen extends StatelessWidget {
  const BookingTimeScreen({
    super.key,
    required this.onTimeSelected,
  });

  final VoidCallback onTimeSelected;

  @override
  Widget build(BuildContext context) {
    final booking = context.read<BookingController>();
    final shop = booking.selectedShop;
    final staff = booking.selectedStaff;
    final date = booking.selectedDate;

    if (shop == null || staff == null || date == null) {
      return const Center(
        child: Text('Booking information is incomplete.'),
      );
    }

    if (booking.totalDurationMinutes <= 0) {
      return const Center(
        child: Text('Please select at least one valid service.'),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => BookingTimeController(
        shopId: shop.id,
        staffId: staff.id,
        bookingDate: date,
        durationMinutes: booking.totalDurationMinutes,
      ),
      child: _BookingTimeView(onTimeSelected: onTimeSelected),
    );
  }
}

class _BookingTimeView extends StatelessWidget {
  const _BookingTimeView({required this.onTimeSelected});

  final VoidCallback onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingTimeController, BookingController>(
      builder: (context, controller, booking, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null) {
          return _MessageState(
            icon: Icons.error_outline,
            title: 'Unable to load available times',
            message: controller.errorMessage!,
            buttonText: 'Try Again',
            onPressed: controller.loadTimes,
          );
        }

        if (controller.times.isEmpty) {
          return _MessageState(
            icon: Icons.event_busy_outlined,
            title: 'No available slots',
            message:
                'There is no ${booking.totalDurationMinutes}-minute continuous slot available for the selected staff member on this date.',
            buttonText: 'Refresh',
            onPressed: controller.loadTimes,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _InfoCard(
                duration: booking.totalDurationMinutes,
                selectedTime: controller.selectedTime,
                endTime: controller.selectedEndTime,
                displayTime: controller.displayTime,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadTimes,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 54,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.times.length,
                  itemBuilder: (context, index) {
                    final time = controller.times[index];
                    final selected = controller.selectedTime == time;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: OutlinedButton(
                        onPressed: () => controller.selectTime(time),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                              : null,
                          side: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(controller.displayTime(time)),
                      ),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: FilledButton(
                      onPressed: controller.canContinue
                          ? () {
                              booking.selectTime(controller.selectedTime!);
                              onTimeSelected();
                            }
                          : null,
                      child: const Text('CONTINUE TO REVIEW 🌸', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.duration,
    required this.selectedTime,
    required this.endTime,
    required this.displayTime,
  });

  final int duration;
  final String? selectedTime;
  final String? endTime;
  final String Function(String) displayTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.pinkAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Selected service duration: $duration minutes', style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            if (selectedTime != null && endTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${displayTime(selectedTime!)} → ${displayTime(endTime!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text('Calculated end time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.pinkAccent),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onPressed(),
              icon: const Icon(Icons.refresh),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}