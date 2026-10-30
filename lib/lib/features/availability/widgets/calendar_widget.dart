import 'package:flutter/material.dart';

class AvailabilityCalendar extends StatelessWidget {
  const AvailabilityCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month),
        title: Text(_format(selectedDate)),
        subtitle: const Text('Tap to select a date'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          );
          if (picked != null) onDateSelected(picked);
        },
      ),
    );
  }

  String _format(DateTime date) =>
      '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';

  String _weekday(int value) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ][value - 1];

  String _month(int value) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][value - 1];
}
