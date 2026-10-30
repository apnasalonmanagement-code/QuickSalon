import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';

class RequestsController extends ChangeNotifier {
  RequestsController({
    AuthService? authService,
  }) : _authService =
            authService ?? AuthService();

  final AuthService _authService;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  List<Map<String, dynamic>> _requests = [];

  List<Map<String, dynamic>> _closedAppointments = [];

  bool _isLoading = false;

  bool _isActionLoading = false;

  String? _errorMessage;

  String? _shopId;

  RealtimeChannel? _realtimeChannel;

  List<Map<String, dynamic>> get requests =>
      List.unmodifiable(_requests);

  List<Map<String, dynamic>> get closedAppointments =>
      List.unmodifiable(_closedAppointments);

  bool get isLoading => _isLoading;

  bool get isActionLoading =>
      _isActionLoading;

  String? get errorMessage =>
      _errorMessage;

  String? get shopId => _shopId;

  int get requestCount =>
      _requests.length;

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  Future<void> initialize() async {
    _errorMessage = null;

    try {
      final user =
          _authService.currentUser;

      if (user == null) {
        throw Exception(
          'No authenticated management user found.',
        );
      }

      final profile =
          await _authService.getProfile(
        user.id,
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
          'No shop is assigned to this account.',
        );
      }

      _shopId = shopId;

      await loadRequests();

      _subscribeToRealtime();
    } catch (e) {
      _errorMessage =
          _cleanError(e);

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD REQUESTS
  // ============================================================

  Future<void> loadRequests() async {
    if (_shopId == null ||
        _shopId!.isEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // STEP 1
      // LOAD PENDING APPOINTMENTS
      //
      // Actual database structure:
      //
      // appointments
      //   id
      //   shop_id
      //   customer_id
      //   staff_id
      //   booking_date
      //   start_time
      //   end_time
      //   services JSONB
      //   total_duration_minutes
      //   total_price
      //   booking_type
      //   status
      // ========================================================

      final response =
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
                shop_instruction
              ''')
              .eq(
                'shop_id',
                _shopId!,
              )
              .inFilter(
                'status',
                ['pending', 'rejected', 'cancelled'],
              )
              .order(
                'booking_date',
                ascending: true,
              )
              .order(
                'start_time',
                ascending: true,
              );

      final rawRequests =
          List<Map<String, dynamic>>.from(
        response,
      );

      // ========================================================
      // STEP 2
      // COLLECT CUSTOMER IDS
      // ========================================================

      final customerIds =
          rawRequests
              .map(
                (request) =>
                    request['customer_id'],
              )
              .where(
                (id) => id != null,
              )
              .map(
                (id) => id.toString(),
              )
              .where(
                (id) => id.isNotEmpty,
              )
              .toSet()
              .toList();

      // ========================================================
      // CUSTOMER MAP
      // ========================================================

      final Map<String, Map<String, dynamic>>
          customersById = {};

      if (customerIds.isNotEmpty) {
        final profilesResponse =
            await _supabase
                .from('profiles')
                .select('''
                  id,
                  name,
                  phone,
                  profile_image_url
                ''')
                .inFilter(
                  'id',
                  customerIds,
                );

        final profiles =
            List<Map<String, dynamic>>.from(
          profilesResponse,
        );

        for (final profile in profiles) {
          final id =
              profile['id']?.toString();

          if (id != null &&
              id.isNotEmpty) {
            customersById[id] =
                profile;
          }
        }
      }

      // ========================================================
      // STEP 3
      // COLLECT STAFF IDS
      // ========================================================

      final staffIds =
          rawRequests
              .map(
                (request) =>
                    request['staff_id'],
              )
              .where(
                (id) => id != null,
              )
              .map(
                (id) => id.toString(),
              )
              .where(
                (id) => id.isNotEmpty,
              )
              .toSet()
              .toList();

      // ========================================================
      // STAFF MAP
      // ========================================================

      final Map<String, Map<String, dynamic>>
          staffById = {};

      if (staffIds.isNotEmpty) {
        final staffResponse =
            await _supabase
                .from('staff')
                .select('''
                  id,
                  name,
                  phone,
                  image_url,
                  role
                ''')
                .inFilter(
                  'id',
                  staffIds,
                );

        final staffList =
            List<Map<String, dynamic>>.from(
          staffResponse,
        );

        for (final staff in staffList) {
          final id =
              staff['id']?.toString();

          if (id != null &&
              id.isNotEmpty) {
            staffById[id] =
                staff;
          }
        }
      }

      // ========================================================
      // STEP 4
      // BUILD FINAL REQUEST OBJECTS
      // ========================================================

      final List<Map<String, dynamic>>
          finalRequests = [];

      for (final request
          in rawRequests) {
        final customerId =
            request['customer_id']
                ?.toString();

        final staffId =
            request['staff_id']
                ?.toString();

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

        // ------------------------------------------------------
        // NORMALIZE SERVICES
        //
        // The database stores services as JSONB.
        //
        // Expected:
        //
        // [
        //   {
        //     service_id: "...",
        //     service_name: "Haircut",
        //     price: 200,
        //     duration: 30,
        //     request: false
        //   }
        // ]
        // ------------------------------------------------------

        final normalizedServices =
            _normalizeServices(
          request['services'],
        );

        final updatedRequest =
            <String, dynamic>{
          ...request,

          // ----------------------------------------------------
          // CUSTOMER DATA
          // ----------------------------------------------------

          '_customer_name':
              customer?['name']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
                  ? customer!['name']
                  : 'Customer',

          '_customer_phone':
              customer?['phone']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
                  ? customer!['phone']
                  : '-',

          '_customer_image':
              customer?[
                    'profile_image_url'
                  ] ??
                  '',

          // ----------------------------------------------------
          // STAFF DATA
          // ----------------------------------------------------

          '_staff_name':
              staff?['name']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
                  ? staff!['name']
                  : 'Staff',

          '_staff_phone':
              staff?['phone']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
                  ? staff!['phone']
                  : '-',

          '_staff_image':
              staff?['image_url'] ??
                  '',

          '_staff_role':
              staff?['role'] ??
                  '',

          // ----------------------------------------------------
          // NORMALIZED SERVICES
          // ----------------------------------------------------

          '_services':
              normalizedServices,
        };

        finalRequests.add(
          updatedRequest,
        );
      }

      _requests = finalRequests.where((request) =>
          request['status']?.toString().toLowerCase() == 'pending').toList();
      _closedAppointments = finalRequests.where((request) {
        final status = request['status']?.toString().toLowerCase();
        return status == 'rejected' || status == 'cancelled';
      }).toList();
    } catch (e) {
      _errorMessage =
          _cleanError(e);

      _requests = [];
      _closedAppointments = [];
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // NORMALIZE SERVICES
  // ============================================================

  List<Map<String, dynamic>>
      _normalizeServices(
    dynamic value,
  ) {
    if (value == null) {
      return [];
    }

    // ----------------------------------------------------------
    // Normal Supabase JSONB response
    // ----------------------------------------------------------

    if (value is List) {
      final List<Map<String, dynamic>>
          result = [];

      for (final item in value) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      return result;
    }

    // ----------------------------------------------------------
    // Sometimes JSON may arrive as a Map
    // ----------------------------------------------------------

    if (value is Map) {
      return [
        Map<String, dynamic>.from(
          value,
        ),
      ];
    }

    return [];
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _subscribeToRealtime() {
    if (_shopId == null ||
        _shopId!.isEmpty) {
      return;
    }

    _realtimeChannel?.unsubscribe();

    _realtimeChannel =
        _supabase.channel(
      'management_requests_$_shopId',
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
        unawaited(
          loadRequests(),
        );
      },
    );

    _realtimeChannel!.subscribe();
  }

  // ============================================================
  // CONFIRM REQUEST
  // ============================================================

  Future<bool> confirmRequest(
    String appointmentId, {
    String? shopInstruction,
  }) async {
    return _updateStatus(
      appointmentId,
      'confirmed',
      shopInstruction: shopInstruction,
    );
  }

  // ============================================================
  // REJECT REQUEST
  // ============================================================

  Future<bool> rejectRequest(
    String appointmentId, {
    String? shopInstruction,
  }) async {
    return _updateStatus(
      appointmentId,
      'rejected',
      shopInstruction: shopInstruction,
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<bool> _updateStatus(
    String appointmentId,
    String status, {
    String? shopInstruction,
  }) async {
    if (_shopId == null ||
        _shopId!.isEmpty) {
      _errorMessage =
          'Shop information is unavailable.';

      notifyListeners();

      return false;
    }

    if (appointmentId.isEmpty) {
      _errorMessage =
          'Appointment information is unavailable.';

      notifyListeners();

      return false;
    }

    if (status != 'confirmed' &&
        status != 'rejected') {
      _errorMessage =
          'Invalid request status.';

      notifyListeners();

      return false;
    }

    _isActionLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // UPDATE ONLY THIS SHOP'S PENDING APPOINTMENT
      // ========================================================

      await _supabase
          .from('appointments')
          .update({
            'status': status,
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
            'pending',
          );

      // ========================================================
      // RELOAD
      // ========================================================

      await loadRequests();

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

  Future<bool> updateInstruction({
    required String appointmentId,
    required String instruction,
  }) async {
    if (_shopId == null || _shopId!.isEmpty) {
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
          .eq('shop_id', _shopId!)
          .eq('status', 'pending');

      await loadRequests();
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
  // CLEAN ERROR
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    final message =
        error.toString();

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();

    _realtimeChannel = null;

    super.dispose();
  }
}