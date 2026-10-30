import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';

class AppointmentsController extends ChangeNotifier {
  AppointmentsController({
    AuthService? authService,
  }) : _authService =
            authService ?? AuthService();

  final AuthService _authService;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  List<Map<String, dynamic>> _appointments = [];

  DateTime _selectedDate =
      DateTime.now();

  bool _isLoading = false;

  bool _isActionLoading = false;

  String? _errorMessage;

  String? _shopId;

  RealtimeChannel? _realtimeChannel;

  // ============================================================
  // GETTERS
  // ============================================================

  List<Map<String, dynamic>>
      get appointments =>
          List.unmodifiable(
            _appointments,
          );

  DateTime get selectedDate =>
      _selectedDate;

  bool get isLoading =>
      _isLoading;

  bool get isActionLoading =>
      _isActionLoading;

  String? get errorMessage =>
      _errorMessage;

  String? get shopId =>
      _shopId;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    _errorMessage = null;

    try {
      final currentUser =
          _authService.currentUser;

      if (currentUser == null) {
        throw Exception(
          'No authenticated management user found.',
        );
      }

      /*
       * IMPORTANT:
       *
       * The actual ApnaSalon database uses:
       *
       * public.profiles
       *
       * for authenticated users.
       *
       * There is no public.users table.
       *
       * The profile contains:
       *
       * id
       * name
       * phone
       * role
       * shop_id
       * profile_image_url
       *
       * Therefore we use the existing AuthService
       * profile architecture instead of querying
       * the non-existing users table.
       */

      final profile =
          await _authService.getProfile(
        currentUser.id,
      );

      if (profile == null) {
        throw Exception(
          'Management profile not found.',
        );
      }

      final role =
          profile['role']?.toString();

      if (role != 'owner' &&
          role != 'manager') {
        throw Exception(
          'You are not authorized to manage this shop.',
        );
      }

      final shopId =
          profile['shop_id']?.toString();

      if (shopId == null ||
          shopId.isEmpty) {
        throw Exception(
          'No shop is assigned to this management account.',
        );
      }

      _shopId = shopId;

      await loadAppointments();

      _subscribeToRealtime();
    } catch (e) {
      _errorMessage =
          _cleanError(e);

      notifyListeners();
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate(
    DateTime date,
  ) async {
    _selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    await loadAppointments();
  }

  // ============================================================
  // LOAD APPOINTMENTS
  // ============================================================

  Future<void> loadAppointments() async {
    if (_shopId == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final dateString =
          _dateToDatabaseString(
        _selectedDate,
      );

      /*
       * IMPORTANT:
       *
       * The actual ApnaSalon appointment schema uses:
       *
       * appointments.shop_id
       * appointments.customer_id
       * appointments.staff_id
       * appointments.booking_date
       * appointments.start_time
       * appointments.end_time
       * appointments.services
       * appointments.total_duration_minutes
       * appointments.total_price
       * appointments.booking_type
       * appointments.status
       * appointments.created_at
       * appointments.updated_at
       * appointments.expires_at
       *
       * Services are stored inside:
       *
       * appointments.services
       *
       * as JSONB.
       *
       * We deliberately do not use:
       *
       * users
       * profiles(...)
       * appointment_services(...)
       * user_id
       * barber_id
       * shop_name_snapshot
       * barber_name_snapshot
       */

      final appointmentsResponse =
          await _supabase
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
                expires_at,
                customer_name_snapshot,
                customer_phone_snapshot,
                shop_instruction
              ''')
              .eq(
                'shop_id',
                _shopId!,
              )
              .eq(
                'booking_date',
                dateString,
              )
              .order(
                'start_time',
                ascending: true,
              );

      final rawAppointments =
          List<Map<String, dynamic>>.from(
        appointmentsResponse,
      ).where((appointment) {
        final status = appointment['status']?.toString().toLowerCase();
        return status != 'rejected' && status != 'cancelled';
      }).toList();

      // ========================================================
      // LOAD CUSTOMER DETAILS
      // ========================================================

      final customerIds =
          rawAppointments
              .map(
                (appointment) =>
                    appointment[
                      'customer_id'
                    ],
              )
              .where(
                (id) => id != null,
              )
              .map(
                (id) => id.toString(),
              )
              .toSet()
              .toList();

      final Map<String,
              Map<String, dynamic>>
          customersById = {};

      if (customerIds.isNotEmpty) {
        final profilesResponse =
            await _supabase
                .from('profiles')
                .select(
                  'id, name, phone, profile_image_url',
                )
                .filter(
                  'id',
                  'in',
                  customerIds,
                );

        for (final profile
            in List<Map<String, dynamic>>.from(
          profilesResponse,
        )) {
          final id =
              profile['id']?.toString();

          if (id != null) {
            customersById[id] =
                profile;
          }
        }
      }

      // ========================================================
      // LOAD STAFF DETAILS
      // ========================================================

      final staffIds =
          rawAppointments
              .map(
                (appointment) =>
                    appointment[
                      'staff_id'
                    ],
              )
              .where(
                (id) => id != null,
              )
              .map(
                (id) => id.toString(),
              )
              .toSet()
              .toList();

      final Map<String,
              Map<String, dynamic>>
          staffById = {};

      if (staffIds.isNotEmpty) {
        final staffResponse =
            await _supabase
                .from('staff')
                .select(
                  'id, name, phone, image_url, role',
                )
                .filter(
                  'id',
                  'in',
                  staffIds,
                );

        for (final staff
            in List<Map<String, dynamic>>.from(
          staffResponse,
        )) {
          final id =
              staff['id']?.toString();

          if (id != null) {
            staffById[id] =
                staff;
          }
        }
      }

      // ========================================================
      // ATTACH CUSTOMER AND STAFF DATA
      // ========================================================

      _appointments =
          rawAppointments.map(
        (appointment) {
          final customerId =
              appointment[
                'customer_id'
              ]?.toString();
          // ========================================================
          final staffId =
              appointment[
                'staff_id'
              ]?.toString();

          final customer =
              customerId == null
                  ? null
                  : customersById[
                      customerId];

          final staff =
              staffId == null
                  ? null
                  : staffById[
                      staffId];

          return {
            ...appointment,

            // --------------------------------------------------
            // Customer data
            // --------------------------------------------------

            '_customer_name':
                (appointment['customer_name_snapshot']?.toString().trim().isNotEmpty == true)
                    ? appointment['customer_name_snapshot']
                    : (customer?['name'] ?? 'Customer'),

            '_customer_phone':
                (appointment['customer_phone_snapshot']?.toString().trim().isNotEmpty == true)
                    ? appointment['customer_phone_snapshot']
                    : (customer?['phone'] ?? '-'),

            '_customer_image':
                customer?[
                      'profile_image_url'
                    ] ??
                    '',

            // --------------------------------------------------
            // Staff data
            // --------------------------------------------------

            '_staff_name':
                staff?['name'] ??
                    'Staff',

            '_staff_phone':
                staff?['phone'] ??
                    '-',

            '_staff_image':
                staff?['image_url'] ??
                    '',

            '_staff_role':
                staff?['role'] ??
                    '',
          };
        },
      ).toList();

      // Completed appointments always stay at the bottom.
      // All other appointments remain above them and are sorted by time.
      _appointments.sort(
        (a, b) {
          final aStatus = a['status']?.toString().toLowerCase();
          final bStatus = b['status']?.toString().toLowerCase();
          final aCompleted = aStatus == 'completed';
          final bCompleted = bStatus == 'completed';

          if (aCompleted != bCompleted) {
            return aCompleted ? 1 : -1;
          }

          final aTime = a['start_time']?.toString() ?? '';
          final bTime = b['start_time']?.toString() ?? '';
          return aTime.compareTo(bTime);
        },
      );
    } catch (e) {
      _errorMessage =
          _cleanError(e);

      _appointments = [];
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _subscribeToRealtime() {
    if (_shopId == null) {
      return;
    }

    _realtimeChannel?.unsubscribe();

    _realtimeChannel =
        _supabase.channel(
      'management_appointments_$_shopId',
    );

    _realtimeChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'appointments',
      filter:
          PostgresChangeFilter(
        type:
            PostgresChangeFilterType.eq,
        column: 'shop_id',
        value: _shopId!,
      ),
      callback: (_) {
        loadAppointments();
      },
    );

    _realtimeChannel!.subscribe();
  }

  // ============================================================
  // VALID STATUS TRANSITIONS
  // ============================================================

  bool canTransition(
    String currentStatus,
    String newStatus,
  ) {
    switch (currentStatus) {
      case 'held':
        return newStatus ==
                'confirmed' ||
            newStatus ==
                'rejected' ||
            newStatus ==
                'cancelled';

      case 'pending':
        return newStatus ==
                'confirmed' ||
            newStatus ==
                'rejected' ||
            newStatus ==
                'cancelled';

      case 'confirmed':
        return newStatus ==
                'completed' ||
            newStatus ==
                'cancelled';

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
  // UPDATE STATUS
  // ============================================================

  Future<bool> updateStatus({
    required String appointmentId,
    required String currentStatus,
    required String newStatus,
    String? shopInstruction,
  }) async {
    if (_shopId == null) {
      _errorMessage =
          'Shop information is unavailable.';

      notifyListeners();

      return false;
    }

    if (!canTransition(
      currentStatus,
      newStatus,
    )) {
      _errorMessage =
          'Invalid status transition: '
          '$currentStatus → $newStatus';

      notifyListeners();

      return false;
    }

    _isActionLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _supabase
          .from('appointments')
          .update({
            'status': newStatus,
            if (shopInstruction != null)
              'shop_instruction': shopInstruction.trim().isEmpty
                  ? null
                  : shopInstruction.trim(),
            'updated_at':
                DateTime.now()
                    .toUtc()
                    .toIso8601String(),
          })
          .eq(
            'id',
            appointmentId,
          )
          .eq(
            'shop_id',
            _shopId!,
          )
          .eq(
            'status',
            currentStatus,
          );

      await loadAppointments();

      return true;
    } catch (e) {
      _errorMessage =
          _cleanError(e);

      return false;
    } finally {
      _isActionLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SHORTCUT ACTIONS
  // ============================================================

  Future<bool> confirm(
    Map<String, dynamic> appointment, {
    String? shopInstruction,
  }) {
    return updateStatus(
      appointmentId:
          appointment['id'].toString(),
      currentStatus:
          appointment['status'].toString(),
      newStatus: 'confirmed',
      shopInstruction: shopInstruction,
    );
  }

  Future<bool> reject(
    Map<String, dynamic> appointment, {
    String? shopInstruction,
  }) {
    return updateStatus(
      appointmentId:
          appointment['id'].toString(),
      currentStatus:
          appointment['status'].toString(),
      newStatus: 'rejected',
      shopInstruction: shopInstruction,
    );
  }

  Future<bool> cancel(
    Map<String, dynamic> appointment, {
    String? shopInstruction,
  }) {
    return updateStatus(
      appointmentId:
          appointment['id'].toString(),
      currentStatus:
          appointment['status'].toString(),
      newStatus: 'cancelled',
      shopInstruction: shopInstruction,
    );
  }

  Future<bool> complete(
    Map<String, dynamic> appointment, {
    String? shopInstruction,
  }) {
    return updateStatus(
      appointmentId:
          appointment['id'].toString(),
      currentStatus:
          appointment['status'].toString(),
      newStatus: 'completed',
      shopInstruction: shopInstruction,
    );
  }

  Future<bool> updateInstruction({
    required String appointmentId,
    required String instruction,
  }) async {
    if (_shopId == null) {
      _errorMessage = 'Shop information is unavailable.';
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase
          .from('appointments')
          .update({
            'shop_instruction': instruction.trim().isEmpty
                ? null
                : instruction.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', appointmentId)
          .eq('shop_id', _shopId!);

      await loadAppointments();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _dateToDatabaseString(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _realtimeChannel
        ?.unsubscribe();

    super.dispose();
  }
}