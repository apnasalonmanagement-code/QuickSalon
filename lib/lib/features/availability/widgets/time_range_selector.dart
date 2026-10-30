import 'package:flutter/material.dart';

class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({
    super.key,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final TimeOfDay? start;
  final TimeOfDay? end;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(start?.format(context) ?? 'Start time'),
            onPressed: () async {
              final value = await showTimePicker(
                context: context,
                initialTime: start ?? TimeOfDay.now(),
              );
              if (value != null) onStartChanged(value);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('to'),
        ),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: Text(end?.format(context) ?? 'End time'),
            onPressed: () async {
              final value = await showTimePicker(
                context: context,
                initialTime: end ?? TimeOfDay.now(),
              );
              if (value != null) onEndChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

