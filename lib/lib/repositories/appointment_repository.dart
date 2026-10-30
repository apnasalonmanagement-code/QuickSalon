import '../core/services/supabase_service.dart';

class AppointmentRepository {
  AppointmentRepository({
    SupabaseService? supabaseService,
  }) : _supabaseService =
            supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  /// Creates an urgent/walk-in booking.
  ///
  /// The database calculates duration and price and performs
  /// the final availability/conflict check.
  Future<Map<String, dynamic>> createUrgentBooking({
    required String shopId,
    required String staffId,
    required String customerName,
    required String customerPhone,
    required DateTime bookingDate,
    required String startTime,
    required List<String> serviceIds,
  }) async {
    if (shopId.trim().isEmpty) {
      throw Exception('Shop information is missing.');
    }

    if (staffId.trim().isEmpty) {
      throw Exception('Staff information is missing.');
    }

    if (customerName.trim().isEmpty) {
      throw Exception('Customer name is required.');
    }

    if (serviceIds.isEmpty) {
      throw Exception(
        'Please select at least one service.',
      );
    }

    final response =
        await _supabaseService.client.rpc(
      'create_urgent_booking',
      params: {
        'p_shop_id': shopId,
        'p_staff_id': staffId,
        'p_customer_name': customerName.trim(),
        'p_customer_phone':
            customerPhone.trim().isEmpty
                ? null
                : customerPhone.trim(),
        'p_booking_date':
            _dateString(bookingDate),
        'p_start_time':
            _normalizeTime(startTime),
        'p_service_ids': serviceIds,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(
        response,
      );
    }

    throw Exception(
      'Unexpected booking response from Supabase.',
    );
  }

  String _dateString(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeTime(
    String value,
  ) {
    final text = value.trim();

    if (text.isEmpty) {
      throw Exception(
        'Booking time is required.',
      );
    }

    if (text.length == 5) {
      return '$text:00';
    }

    if (text.length >= 8) {
      return text.substring(0, 8);
    }

    throw Exception(
      'Invalid booking time.',
    );
  }
}