import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  AppointmentRepository({
    SupabaseClient? client,
  }) : _client =
            client ??
                SupabaseService.client;

  final SupabaseClient _client;

  // ============================================================
  // PART 7
  // EXISTING CUSTOMER BOOKING
  // ============================================================

  Future<Map<String, dynamic>>
      createCustomerBooking({
    required String shopId,
    required String staffId,
    required DateTime bookingDate,
    required String startTime,
    required List<String> serviceIds,
  }) async {
    final response =
        await _client.rpc(
      'create_customer_booking',
      params: {
        'p_shop_id': shopId,
        'p_staff_id': staffId,
        'p_booking_date':
            _dateString(
          bookingDate,
        ),
        'p_start_time':
            _normalizeTime(
          startTime,
        ),
        'p_service_ids':
            serviceIds,
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

  // ============================================================
  // LOAD CUSTOMER APPOINTMENTS
  // ============================================================

  Future<List<AppointmentModel>>
      loadCustomerAppointments(
    String customerId,
  ) async {
    if (customerId.trim().isEmpty) {
      return const [];
    }

    // IMPORTANT:
    //
    // customer_id is explicitly filtered here.
    //
    // RLS must still enforce this at database level,
    // but the application query itself also never
    // requests another customer's appointments.

    final response =
        await _client
            .from('appointments')
            .select('''
              id,
              shop_id,
              customer_id,
              staff_id,
              booking_date,
              start_time,
              end_time,
              services,
              total_duration_minutes,
              total_price,
              booking_type,
              status,
              created_at,
              updated_at,
              expires_at
            ''')
            .eq(
              'customer_id',
              customerId,
            )
            .order(
              'booking_date',
              ascending: true,
            )
            .order(
              'start_time',
              ascending: true,
            );

    final rawAppointments =
        List<Map<String, dynamic>>.from(
      response,
    );

    if (rawAppointments.isEmpty) {
      return const [];
    }

    // ==========================================================
    // COLLECT SHOP IDS
    // ==========================================================

    final shopIds =
        rawAppointments
            .map(
              (appointment) =>
                  appointment[
                    'shop_id'
                  ]
                      ?.toString(),
            )
            .whereType<String>()
            .where(
              (id) =>
                  id.isNotEmpty,
            )
            .toSet()
            .toList();

    // ==========================================================
    // COLLECT STAFF IDS
    // ==========================================================

    final staffIds =
        rawAppointments
            .map(
              (appointment) =>
                  appointment[
                    'staff_id'
                  ]
                      ?.toString(),
            )
            .whereType<String>()
            .where(
              (id) =>
                  id.isNotEmpty,
            )
            .toSet()
            .toList();

    final shopsById =
        <String,
            Map<String, dynamic>>{};

    final staffById =
        <String,
            Map<String, dynamic>>{};

    // ==========================================================
    // LOAD SHOPS
    // ==========================================================

    if (shopIds.isNotEmpty) {
      final shopsResponse =
          await _client
              .from('shops')
              .select(
                '''
                id,
                shop_name,
                image_url
                ''',
              )
              .inFilter(
                'id',
                shopIds,
              );

      final shops =
          List<Map<String, dynamic>>
              .from(
        shopsResponse,
      );

      for (final shop in shops) {
        final id =
            shop['id']
                ?.toString();

        if (id != null &&
            id.isNotEmpty) {
          shopsById[id] =
              shop;
        }
      }
    }

    // ==========================================================
    // LOAD STAFF
    // ==========================================================

    if (staffIds.isNotEmpty) {
      final staffResponse =
          await _client
              .from('staff')
              .select(
                '''
                id,
                name,
                image_url
                ''',
              )
              .inFilter(
                'id',
                staffIds,
              );

      final staffList =
          List<Map<String, dynamic>>
              .from(
        staffResponse,
      );

      for (final staff
          in staffList) {
        final id =
            staff['id']
                ?.toString();

        if (id != null &&
            id.isNotEmpty) {
          staffById[id] =
              staff;
        }
      }
    }

    // ==========================================================
    // BUILD APPOINTMENT MODELS
    // ==========================================================

    return rawAppointments.map(
      (appointment) {
        final shop =
            shopsById[
                appointment[
                  'shop_id'
                ]
                    ?.toString()
            ];

        final staff =
            staffById[
                appointment[
                  'staff_id'
                ]
                    ?.toString()
            ];

        return AppointmentModel.fromMap(
          {
            ...appointment,

            '_shop_name':
                shop?[
                  'shop_name'
                ],

            '_shop_image':
                shop?[
                  'image_url'
                ],

            '_staff_name':
                staff?[
                  'name'
                ],

            '_staff_image':
                staff?[
                  'image_url'
                ],
          },
        );
      },
    ).toList();
  }

  // ============================================================
  // CUSTOMER CANCEL
  // ============================================================

  Future<void>
      cancelCustomerAppointment({
    required String appointmentId,
    required String customerId,
    required String currentStatus,
  }) async {
    if (!canCustomerCancel(
      currentStatus,
    )) {
      throw Exception(
        'This appointment can no longer be cancelled.',
      );
    }

    await _client
        .from('appointments')
        .update(
          {
            'status':
                'cancelled',

            'updated_at':
                DateTime.now()
                    .toUtc()
                    .toIso8601String(),
          },
        )
        .eq(
          'id',
          appointmentId,
        )
        .eq(
          'customer_id',
          customerId,
        )
        .eq(
          'status',
          currentStatus,
        );
  }

  // ============================================================
  // EXISTING STATUS TRANSITION RULES
  // ============================================================

  static bool
      canCustomerCancel(
    String status,
  ) {
    switch (
        status.toLowerCase()) {
      case 'held':
      case 'pending':
      case 'confirmed':
        return true;

      case 'rejected':
      case 'cancelled':
      case 'completed':
      case 'expired':
        return false;

      default:
        return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

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
    final text =
        value.trim();

    if (text.length == 5) {
      return '$text:00';
    }

    if (text.length >= 8) {
      return text.substring(
        0,
        8,
      );
    }

    throw Exception(
      'Invalid booking time.',
    );
  }
}