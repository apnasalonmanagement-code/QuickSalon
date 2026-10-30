import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../models/availability_model.dart';
import '../../repositories/availability_repository.dart';
import 'availability_controller.dart';
import 'widgets/calendar_widget.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  late final AvailabilityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AvailabilityController();
    _controller.addListener(_refresh);
    _controller.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isBoy = themeNotifier.currentTheme == SalonGenderTheme.boy;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.boy, color: isBoy ? Colors.white : Colors.white70, size: 28),
                  onPressed: () => themeNotifier.setTheme(SalonGenderTheme.boy),
                  tooltip: 'Blue Boy Theme',
                ),
                IconButton(
                  icon: Icon(Icons.girl, color: !isBoy ? Colors.white : Colors.white70, size: 28),
                  onPressed: () => themeNotifier.setTheme(SalonGenderTheme.girl),
                  tooltip: 'Pink Girl Theme',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isBoy
                ? [const Color(0xFFF0F8FF), Colors.white]
                : [const Color(0xFFFFF0F5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _controller.isLoading && _controller.records.isEmpty
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: () => _controller.loadForDate(_controller.selectedDate),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    AvailabilityCalendar(
                      selectedDate: _controller.selectedDate,
                      onDateSelected: _controller.loadForDate,
                    ),
                    const SizedBox(height: 16),
                    if (_controller.errorMessage != null)
                      _ErrorCard(message: _controller.errorMessage!),
                    _DateConfigurationCard(
                      controller: _controller,
                      key: ValueKey(
                        '${_controller.selectedDate.year}-${_controller.selectedDate.month}-${_controller.selectedDate.day}-${_controller.records.length}',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExistingRecords(records: _controller.records),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DateConfigurationCard extends StatefulWidget {
  const _DateConfigurationCard({super.key, required this.controller});

  final AvailabilityController controller;

  @override
  State<_DateConfigurationCard> createState() => _DateConfigurationCardState();
}

class _DateConfigurationCardState extends State<_DateConfigurationCard> {
  bool _holiday = false;
  late Map<String, bool> _staffStatus;
  late TextEditingController _reasonController;
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _staffStatus = {
      for (final item in widget.controller.staff)
        item['id'].toString(): true,
    };
    _loadExisting();
  }

  void _loadExisting() {
    final records = widget.controller.records;
    final holiday = records.where(
      (e) => e.staffId == null && e.type == 'holiday' && e.status,
    ).cast<AvailabilityModel?>().firstOrNull;

    if (holiday != null) {
      _holiday = true;
      _reasonController.text = holiday.reason ?? '';
      return;
    }

    final shopWorking = records.where(
      (e) => e.staffId == null && e.type == 'working' && e.status,
    ).cast<AvailabilityModel?>().firstOrNull;

    if (shopWorking != null) {
      _start = _parseTime(shopWorking.startTime);
      _end = _parseTime(shopWorking.endTime);
    }

    for (final person in widget.controller.staff) {
      final id = person['id'].toString();
      final working = records.any(
        (e) => e.staffId == id && e.type == 'working' && e.status,
      );
      final off = records.any(
        (e) =>
            e.staffId == id &&
            e.type == 'leave' &&
            e.status &&
            e.reason == 'Day configuration: staff off',
      );
      if (working) _staffStatus[id] = true;
      if (off) _staffStatus[id] = false;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final date = controller.selectedDate;
    final hasExisting = controller.records.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 5,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_weekday(date.weekday)}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                ),
                if (hasExisting)
                  Chip(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    label: Text('Edit configuration', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'One date configuration controls the shop and all staff together. Save again to edit this date.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Center(
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: primaryColor.withOpacity(0.2),
                  selectedForegroundColor: primaryColor,
                ),
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.business_center_outlined),
                    label: Text('Working Day'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.beach_access_outlined),
                    label: Text('Holiday'),
                  ),
                ],
                selected: {_holiday},
                onSelectionChanged: (value) {
                  setState(() => _holiday = value.first);
                },
              ),
            ),
            const SizedBox(height: 18),
            if (_holiday) ...[
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Holiday reason',
                  hintText: 'Example: Festival / Shop closed',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start time',
                      value: _formatTime(_start),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'End time',
                      value: _formatTime(_end),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Staff working on this day',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Turn OFF a staff member to block that person from slot creation for this selected date.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (controller.staff.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No active staff found for this shop.'),
                )
              else
                ...controller.staff.map((person) {
                  final id = person['id'].toString();
                  final enabled = _staffStatus[id] ?? true;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile.adaptive(
                      activeColor: primaryColor,
                      value: enabled,
                      onChanged: (value) {
                        setState(() => _staffStatus[id] = value);
                      },
                      title: Text(person['name']?.toString() ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(person['role']?.toString() ?? 'Staff'),
                      secondary: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.15),
                        child: Text(
                          _initial(person['name']?.toString()),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: controller.isSaving ? null : _save,
                icon: controller.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(hasExisting ? Icons.save_outlined : Icons.add_task_outlined),
                label: Text(
                  controller.isSaving
                      ? 'Saving...'
                      : hasExisting
                          ? 'Update selected date'
                          : 'Save selected date',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(bool start) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final result = await showTimePicker(
      context: context,
      initialTime: start
          ? (_start ?? const TimeOfDay(hour: 9, minute: 0))
          : (_end ?? const TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      if (start) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  Future<void> _save() async {
    if (_holiday) {
      if (_reasonController.text.trim().isEmpty) {
        _message('Please enter a holiday reason.');
        return;
      }
    } else {
      if (_start == null || _end == null) {
        _message('Please select start and end time.');
        return;
      }
      if (_minutes(_end!) <= _minutes(_start!)) {
        _message('End time must be after start time.');
        return;
      }
      if (!_staffStatus.values.any((value) => value)) {
        _message('Turn ON at least one staff member.');
        return;
      }
    }

    final ok = await widget.controller.saveDateConfiguration(
      isHoliday: _holiday,
      reason: _holiday ? _reasonController.text.trim() : null,
      startTime: _holiday ? null : _toDatabaseTime(_start!),
      endTime: _holiday ? null : _toDatabaseTime(_end!),
      staffStatus: _holiday ? const {} : _staffStatus,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            _holiday
                ? 'Holiday saved successfully.'
                : 'Working day and staff configuration saved successfully.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      _message(widget.controller.errorMessage ?? 'Unable to save configuration.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ExistingRecords extends StatelessWidget {
  const _ExistingRecords({required this.records});
  final List<AvailabilityModel> records;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (records.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No date-specific configuration saved for this date yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved records', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 8),
            ...records.map((record) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon(record.type), color: primaryColor, size: 20),
                  ),
                  title: Text(record.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${record.staffId == null ? 'Shop' : 'Staff'} • ${record.status ? 'Active' : 'Inactive'}'
                    '${record.startTime == null ? '' : ' • ${record.startTime} - ${record.endTime}'}'
                    '${record.reason == null ? '' : '\n${record.reason}'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'holiday': return Icons.beach_access_outlined;
      case 'leave': return Icons.event_busy_outlined;
      case 'break': return Icons.free_breakfast_outlined;
      default: return Icons.work_outline;
    }
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
        ),
      );
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

TimeOfDay? _parseTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay? value) {
  if (value == null) return 'Select time';
  final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.period == DayPeriod.am ? 'AM' : 'PM'}';
}

String _toDatabaseTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

String _weekday(int value) {
  const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return names[value - 1];
}

String _initial(String? name) {
  final value = name?.trim() ?? '';
  return value.isEmpty ? '?' : value.substring(0, 1).toUpperCase();
}
