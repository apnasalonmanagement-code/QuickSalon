import 'package:flutter/material.dart';

import '../../../models/availability_model.dart';

class StaffAvailabilityItem extends StatelessWidget {
  const StaffAvailabilityItem({
    super.key,
    required this.staffName,
    required this.records,
    required this.onEdit,
    required this.onToggle,
  });

  final String staffName;
  final List<AvailabilityModel> records;
  final ValueChanged<AvailabilityModel> onEdit;
  final ValueChanged<AvailabilityModel> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(staffName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (records.isEmpty)
              const Text('No availability configured for this date.')
            else
              ...records.map(
                (record) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_title(record)),
                  subtitle: Text(
                    '${record.startTime ?? ''}${record.endTime == null ? '' : ' → ${record.endTime}'}${record.reason == null ? '' : '\n${record.reason}'}',
                  ),
                  leading: Icon(_icon(record.type)),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      Switch(
                        value: record.status,
                        onChanged: (_) => onToggle(record),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(record),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _title(AvailabilityModel record) {
    final text = record.type[0].toUpperCase() + record.type.substring(1);
    return record.status ? text : '$text • Inactive';
  }

  IconData _icon(String type) {
    switch (type) {
      case 'break': return Icons.free_breakfast_outlined;
      case 'leave': return Icons.event_busy_outlined;
      default: return Icons.work_outline;
    }
  }
}
