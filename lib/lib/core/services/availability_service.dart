import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AvailabilityService {
  AvailabilityService({
    SupabaseService? supabaseService,
  }) : _supabaseService =
            supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  SupabaseClient get _client =>
      _supabaseService.client;

  Future<List<String>> getUrgentStartTimes({
    required String shopId,
    required String staffId,
    required DateTime date,
    required int durationMinutes,
  }) async {
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
        'Invalid booking duration.',
      );
    }

    if (durationMinutes % 15 != 0) {
      throw Exception(
        'Service duration must be a multiple of 15 minutes.',
      );
    }

    final response =
        await _client.rpc(
      'calculate_urgent_availability',
      params: {
        'p_shop_id': shopId,
        'p_staff_id': staffId,
        'p_booking_date':
            _dateString(date),
        'p_duration_minutes':
            durationMinutes,
      },
    );

    if (response == null) {
      return <String>[];
    }

    final rows =
        List<Map<String, dynamic>>.from(
      response as List,
    );

    final result = rows
        .map(
          (row) =>
              row['start_time']?.toString(),
        )
        .whereType<String>()
        .map(
          (time) =>
              time.length >= 5
                  ? time.substring(0, 5)
                  : time,
        )
        .toList();

    result.sort();

    return result;
  }

  String _dateString(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}