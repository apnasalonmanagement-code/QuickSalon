import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment_model.dart';
import '../../repositories/appointment_repository.dart';

enum AppointmentFilter {
  upcoming,
  pending,
  past,
  cancelled,
}

class AppointmentsController
    extends ChangeNotifier {
  AppointmentsController({
    AppointmentRepository?
        repository,
    SupabaseClient? client,
  })  : _repository =
            repository ??
                AppointmentRepository(
                  client: client,
                ),
        _client =
            client ??
                Supabase.instance.client;

  final AppointmentRepository
      _repository;

  final SupabaseClient
      _client;

  List<AppointmentModel>
      _appointments = const [];

  AppointmentFilter _filter =
      AppointmentFilter.upcoming;

  bool _isLoading = false;

  bool _isActionLoading =
      false;

  String? _errorMessage;

  String? _customerId;

  RealtimeChannel?
      _realtimeChannel;

  // ============================================================
  // GETTERS
  // ============================================================

  List<AppointmentModel>
      get appointments =>
          List.unmodifiable(
            _appointments,
          );

  AppointmentFilter
      get filter =>
          _filter;

  bool get isLoading =>
      _isLoading;

  bool get isActionLoading =>
      _isActionLoading;

  String? get errorMessage =>
      _errorMessage;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void>
      initialize() async {
    final user =
        _client.auth.currentUser;

    if (user == null) {
      _appointments =
          const [];

      _errorMessage =
          'Please sign in to view your appointments.';

      notifyListeners();

      return;
    }

    _customerId =
        user.id;

    await loadAppointments();

    _subscribeToRealtime();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void>
      loadAppointments() async {
    final customerId =
        _customerId ??
            _client
                .auth
                .currentUser
                ?.id;

    if (customerId == null ||
        customerId.isEmpty) {
      _appointments =
          const [];

      _errorMessage =
          'Please sign in to view your appointments.';

      notifyListeners();

      return;
    }

    _customerId =
        customerId;

    _isLoading =
        true;

    _errorMessage =
        null;

    notifyListeners();

    try {
      _appointments =
          await _repository
              .loadCustomerAppointments(
        customerId,
      );

      _sortAllAppointments();
    } catch (error) {
      _appointments =
          const [];

      _errorMessage =
          _cleanError(
        error,
      );
    } finally {
      _isLoading =
          false;

      notifyListeners();
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  void setFilter(
    AppointmentFilter value,
  ) {
    if (_filter ==
        value) {
      return;
    }

    _filter =
        value;

    notifyListeners();
  }

  List<AppointmentModel>
      get filteredAppointments {
    final now =
        DateTime.now();

    final result =
        _appointments.where(
      (appointment) {
        final status =
            appointment.status;

        switch (_filter) {
          // ====================================================
          // UPCOMING
          //
          // Active appointments scheduled now/future.
          // Pending is shown separately.
          // ====================================================

          case AppointmentFilter
                .upcoming:
            return const {
                  'held',
                  'confirmed',
                }.contains(
                  status,
                ) &&
                !appointment
                    .scheduledAt
                    .isBefore(
                      now,
                    );

          // ====================================================
          // PENDING
          // ====================================================

          case AppointmentFilter
                .pending:
            return status ==
                'pending';

          // ====================================================
          // PAST
          //
          // Completed appointments plus active appointments
          // whose scheduled time has already passed.
          // ====================================================

          case AppointmentFilter
                .past:
            return status ==
                    'completed' ||
                ((status ==
                            'held' ||
                        status ==
                            'confirmed') &&
                    appointment
                        .scheduledAt
                        .isBefore(
                          now,
                        ));

          // ====================================================
          // CANCELLED
          //
          // Terminal non-completed states.
          // ====================================================

          case AppointmentFilter
                .cancelled:
            return const {
              'rejected',
              'cancelled',
              'expired',
            }.contains(
              status,
            );
        }
      },
    ).toList();

    result.sort(
      (a, b) {
        if (_filter ==
                AppointmentFilter
                    .past ||
            _filter ==
                AppointmentFilter
                    .cancelled) {
          return b
              .scheduledAt
              .compareTo(
                a.scheduledAt,
              );
        }

        return a
            .scheduledAt
            .compareTo(
              b.scheduledAt,
            );
      },
    );

    return result;
  }

  // ============================================================
  // CANCEL
  // ============================================================

  bool canCancel(
    AppointmentModel
        appointment,
  ) {
    return AppointmentRepository
        .canCustomerCancel(
      appointment.status,
    );
  }

  Future<bool>
      cancelAppointment(
    AppointmentModel
        appointment,
  ) async {
    final customerId =
        _customerId ??
            _client
                .auth
                .currentUser
                ?.id;

    if (customerId == null ||
        customerId.isEmpty) {
      _errorMessage =
          'Please sign in again.';

      notifyListeners();

      return false;
    }

    if (!canCancel(
      appointment,
    )) {
      _errorMessage =
          'This appointment can no longer be cancelled.';

      notifyListeners();

      return false;
    }

    _isActionLoading =
        true;

    _errorMessage =
        null;

    notifyListeners();

    try {
      await _repository
          .cancelCustomerAppointment(
        appointmentId:
            appointment.id,
        customerId:
            customerId,
        currentStatus:
            appointment.status,
      );

      await loadAppointments();

      return true;
    } catch (error) {
      _errorMessage =
          _cleanError(
        error,
      );

      return false;
    } finally {
      _isActionLoading =
          false;

      notifyListeners();
    }
  }

  // ============================================================
  // SORTING
  // ============================================================

  void _sortAllAppointments() {
    _appointments.sort(
      (a, b) {
        final aGroup =
            _globalSortGroup(
          a,
        );

        final bGroup =
            _globalSortGroup(
          b,
        );

        if (aGroup !=
            bGroup) {
          return aGroup.compareTo(
            bGroup,
          );
        }

        if (aGroup <= 1) {
          return a
              .scheduledAt
              .compareTo(
                b.scheduledAt,
              );
        }

        return b
            .scheduledAt
            .compareTo(
              a.scheduledAt,
            );
      },
    );
  }

  int _globalSortGroup(
    AppointmentModel
        appointment,
  ) {
    final now =
        DateTime.now();

    // Upcoming active first.
    if ((appointment.status ==
                'held' ||
            appointment.status ==
                'confirmed') &&
        !appointment
            .scheduledAt
            .isBefore(
              now,
            )) {
      return 0;
    }

    // Pending after upcoming active.
    if (appointment.status ==
        'pending') {
      return 1;
    }

    // Completed/past lower.
    if (appointment.status ==
            'completed' ||
        ((appointment.status ==
                    'held' ||
                appointment.status ==
                    'confirmed') &&
            appointment
                .scheduledAt
                .isBefore(
                  now,
                ))) {
      return 2;
    }

    // Rejected / cancelled / expired.
    return 3;
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _subscribeToRealtime() {
    final customerId =
        _customerId;

    if (customerId == null ||
        customerId.isEmpty) {
      return;
    }

    _realtimeChannel
        ?.unsubscribe();

    _realtimeChannel =
        _client.channel(
      'customer_appointments_$customerId',
    );

    _realtimeChannel!
        .onPostgresChanges(
      event:
          PostgresChangeEvent
              .all,

      schema:
          'public',

      table:
          'appointments',

      filter:
          PostgresChangeFilter(
        type:
            PostgresChangeFilterType
                .eq,

        column:
            'customer_id',

        value:
            customerId,
      ),

      callback: (_) {
        unawaited(
          loadAppointments(),
        );
      },
    );

    _realtimeChannel!
        .subscribe();
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