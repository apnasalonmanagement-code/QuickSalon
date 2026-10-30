import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/availability_repository.dart';

class UrgentTimeController extends ChangeNotifier {
  UrgentTimeController({
    required this.shopId,
    required this.staffId,
    required this.bookingDate,
    required this.durationMinutes,
    AvailabilityRepository? repository,
  }) : _repository =
            repository ?? AvailabilityRepository() {
    loadTimes();
    _subscribeToAppointmentChanges();
  }

  final String shopId;
  final String staffId;
  final DateTime bookingDate;
  final int durationMinutes;

  final AvailabilityRepository _repository;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool isLoading = false;

  String? errorMessage;

  List<String> times =
      <String>[];

  String? selectedTime;

  RealtimeChannel?
      _realtimeChannel;

  bool _disposed = false;

  Future<void> loadTimes() async {
    if (_disposed) {
      return;
    }

    isLoading = true;

    errorMessage = null;

    final previouslySelectedTime =
        selectedTime;

    notifyListeners();

    try {
      if (shopId.trim().isEmpty) {
        throw Exception(
          'Shop information is missing.',
        );
      }

      if (staffId.trim().isEmpty) {
        throw Exception(
          'Staff information is missing.',
        );
      }

      if (durationMinutes <= 0) {
        throw Exception(
          'Service duration must be greater than zero.',
        );
      }

      final availableTimes =
          await _repository
              .getUrgentStartTimes(
        shopId: shopId,
        staffId: staffId,
        date: bookingDate,
        durationMinutes:
            durationMinutes,
      );

      if (_disposed) {
        return;
      }

      times = _removePastTimes(availableTimes);

      // Keep selection only if it is STILL available and not in the past.
      if (previouslySelectedTime != null &&
          times.contains(
            previouslySelectedTime,
          )) {
        selectedTime =
            previouslySelectedTime;
      } else {
        selectedTime = null;
      }
    } catch (e) {
      times = <String>[];

      selectedTime = null;

      errorMessage =
          _cleanErrorMessage(e);
    } finally {
      isLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  List<String> _removePastTimes(List<String> values) {
    final now = DateTime.now();
    final selectedDay = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAfter(today)) return List<String>.from(values)..sort();
    if (selectedDay.isBefore(today)) return <String>[];

    return values.where((value) {
      final parts = value.split(':');
      if (parts.length < 2) return false;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return false;
      final slot = DateTime(now.year, now.month, now.day, hour, minute);
      return slot.isAfter(now);
    }).toList()..sort();
  }

  void _subscribeToAppointmentChanges() {
    final date =
        _dateString(bookingDate);

    _realtimeChannel =
        _supabase.channel(
      'urgent_slots_'
      '${shopId}_'
      '${staffId}_'
      '$date',
    )
          ..onPostgresChanges(
            event:
                PostgresChangeEvent.all,
            schema: 'public',
            table: 'appointments',
            filter:
                PostgresChangeFilter(
              type:
                  PostgresChangeFilterType.eq,
              column: 'staff_id',
              value: staffId,
            ),
            callback: (_) {
              loadTimes();
            },
          )
          ..subscribe();
  }

  void selectTime(
    String time,
  ) {
    if (!times.contains(time)) {
      return;
    }

    selectedTime = time;

    notifyListeners();
  }

  String displayTime(
    String value,
  ) {
    final parts =
        value.split(':');

    if (parts.length < 2) {
      return value;
    }

    final hour =
        int.tryParse(parts[0]);

    final minute =
        int.tryParse(parts[1]);

    if (hour == null ||
        minute == null) {
      return value;
    }

    final isPm =
        hour >= 12;

    final displayHour =
        hour % 12 == 0
            ? 12
            : hour % 12;

    return '$displayHour:'
        '${minute.toString().padLeft(2, '0')} '
        '${isPm ? 'PM' : 'AM'}';
  }

  String _dateString(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  @override
  void dispose() {
    _disposed = true;

    _realtimeChannel
        ?.unsubscribe();

    super.dispose();
  }
}