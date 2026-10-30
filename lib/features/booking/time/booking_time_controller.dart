
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/availability_repository.dart';

class BookingTimeController extends ChangeNotifier {
  BookingTimeController({
    required this.shopId,
    required this.staffId,
    required this.bookingDate,
    required this.durationMinutes,
    this.initialSelectedTime,
    AvailabilityRepository? repository,
    SupabaseClient? client,
  })  : _repository = repository ?? AvailabilityRepository(),
        _client = client ?? Supabase.instance.client {
    loadTimes();
    _startRealtime();
  }

  final String shopId;
  final String staffId;
  final DateTime bookingDate;
  final int durationMinutes;
  final String? initialSelectedTime;
  final AvailabilityRepository _repository;
  final SupabaseClient _client;

  RealtimeChannel? _availabilityChannel;
  RealtimeChannel? _appointmentsChannel;

  bool isLoading = false;
  String? errorMessage;
  List<String> times = <String>[];
  String? selectedTime;

  bool get canContinue => selectedTime != null;

  Future<void> loadTimes() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (shopId.trim().isEmpty) {
        throw Exception('Shop information is missing.');
      }
      if (staffId.trim().isEmpty) {
        throw Exception('Staff information is missing.');
      }
      if (durationMinutes <= 0) {
        throw Exception('Service duration must be greater than zero.');
      }

      final availableTimes = await _repository.getCustomerStartTimes(
        shopId: shopId,
        staffId: staffId,
        date: bookingDate,
        durationMinutes: durationMinutes,
      );

      times = _removePastAndTooSoonSlots(availableTimes);

      final previousSelection = selectedTime ?? initialSelectedTime;

      selectedTime =
          previousSelection != null && times.contains(previousSelection)
              ? previousSelection
              : null;
    } catch (error) {
      times = <String>[];
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Removes past time slots and slots that are too soon to book.
  List<String> _removePastAndTooSoonSlots(List<String> availableTimes) {
    final now = DateTime.now();

    final bookingDay = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );

    final today = DateTime(now.year, now.month, now.day);

    if (bookingDay.isBefore(today)) {
      return <String>[];
    }

    // Keep all available slots on future dates.
    if (bookingDay.isAfter(today)) {
      return List<String>.from(availableTimes);
    }

    // For today's bookings, exclude times that have already passed.
    return availableTimes.where((time) {
      final normalized = _normalizeTime(time);
      final parts = normalized.split(':');

      if (parts.length < 2) {
        return false;
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return false;
      }

      final slotTime = DateTime(
        bookingDay.year,
        bookingDay.month,
        bookingDay.day,
        hour,
        minute,
      );

      return slotTime.isAfter(now);
    }).toList();
  }

  void selectTime(String time) {
    if (!times.contains(time)) return;
    selectedTime = time;
    notifyListeners();
  }

  String? get selectedEndTime {
    final time = selectedTime;
    if (time == null) return null;
    return calculateEndTime(time);
  }

  String calculateEndTime(String startTime) {
    final normalized = _normalizeTime(startTime);
    final parts = normalized.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final total = hour * 60 + minute + durationMinutes;
    final endHour = total ~/ 60;
    final endMinute = total % 60;
    return '${endHour.toString().padLeft(2, '0')}:'
        '${endMinute.toString().padLeft(2, '0')}:00';
  }

  String displayTime(String value) {
    final normalized = _normalizeTime(value);
    final parts = normalized.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;

    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} '
        '${isPm ? 'PM' : 'AM'}';
  }

  String _normalizeTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return value.trim();
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  void _startRealtime() {
    _availabilityChannel = _client
        .channel(
          'user-booking-availability-$shopId-$staffId-${_dateString(bookingDate)}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'availability',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: shopId,
          ),
          callback: (_) => loadTimes(),
        )
        .subscribe();

    _appointmentsChannel = _client
        .channel(
          'user-booking-appointments-$shopId-$staffId-${_dateString(bookingDate)}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: shopId,
          ),
          callback: (_) => loadTimes(),
        )
        .subscribe();
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _cleanErrorMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    if (_availabilityChannel != null) {
      _client.removeChannel(_availabilityChannel!);
    }
    if (_appointmentsChannel != null) {
      _client.removeChannel(_appointmentsChannel!);
    }
    super.dispose();
  }
}
