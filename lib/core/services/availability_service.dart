import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Customer-side gateway to the shared server-side availability engine.
///
/// IMPORTANT:
/// This class intentionally performs no availability calculation in Flutter.
/// The database RPC is the single source of truth so customer booking and
/// management booking follow the same availability rules.
class AvailabilityService {
  AvailabilityService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<List<String>> getCustomerStartTimes({
    required String shopId,
    required String staffId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    if (shopId.trim().isEmpty) {
      throw Exception('Shop information is missing.');
    }
    if (staffId.trim().isEmpty) {
      throw Exception('Staff information is missing.');
    }
    if (durationMinutes <= 0) {
      throw Exception('Service duration must be greater than zero.');
    }
    if (durationMinutes % 15 != 0) {
      throw Exception('Service duration must be a multiple of 15 minutes.');
    }

    final response = await _client.rpc(
      // This is the customer-safe RPC. It must use the SAME availability
      // engine/rules as calculate_urgent_availability without the management
      // authorization restriction that caused P0001 for customer accounts.
      'calculate_customer_availability',
      params: {
        'p_shop_id': shopId,
        'p_staff_id': staffId,
        'p_booking_date': _dateString(date),
        'p_duration_minutes': durationMinutes,
      },
    );

    if (response == null) return <String>[];

    final rows = List<Map<String, dynamic>>.from(response as List);
    final times = rows
        .map((row) => row['start_time']?.toString())
        .whereType<String>()
        .map((value) => value.length >= 5 ? value.substring(0, 5) : value)
        .toList();

    times.sort();
    return times;
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
