import '../core/services/auth_service.dart';
import '../models/availability_model.dart';

class AvailabilityRepository {
  AvailabilityRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  // ============================================================
  // MANAGEMENT SHOP
  // ============================================================

  Future<List<AvailabilityModel>> getDateConfiguration(
    DateTime date,
  ) async {
    final shopId = await getManagementShopId();
    final dateText = _date(date);

    final rows = await _authService.client
        .from('availability')
        .select()
        .eq('shop_id', shopId)
        .eq('date', dateText)
        .order('staff_id', ascending: true)
        .order('start_time', ascending: true);

    return _map(rows);
  }

  /// Saves ONE date configuration.
  ///
  /// Date-specific working rows created by this screen are replaced on edit.
  /// Existing break/leave records created elsewhere are preserved.
  Future<void> saveDateConfiguration({
    required DateTime date,
    required bool isHoliday,
    String? reason,
    String? startTime,
    String? endTime,
    required Map<String, bool> staffStatus,
  }) async {
    final shopId = await getManagementShopId();
    final dateText = _date(date);

    if (isHoliday) {
      if (reason == null || reason.trim().isEmpty) {
        throw Exception('Holiday reason is required.');
      }
    } else {
      if (startTime == null || endTime == null) {
        throw Exception('Start time and end time are required.');
      }
      if (_minutes(endTime) <= _minutes(startTime)) {
        throw Exception('End time must be after start time.');
      }
      if (staffStatus.isEmpty) {
        throw Exception('No active staff members were found.');
      }
      if (!staffStatus.values.any((value) => value)) {
        throw Exception('Turn ON at least one staff member.');
      }
    }

    // Remove only the rows owned by this date-configuration UI.
    // Do NOT delete unrelated date-specific breaks/leaves.
    final oldRows = await _authService.client
        .from('availability')
        .select('id,staff_id,type,reason')
        .eq('shop_id', shopId)
        .eq('date', dateText);

    final generatedIds = <String>[];
    for (final raw in oldRows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final type = row['type']?.toString();
      final staffId = row['staff_id']?.toString();
      final rowReason = row['reason']?.toString() ?? '';
      final isGeneratedStaffOff = type == 'leave' &&
          rowReason == 'Day configuration: staff off';
      final isShopConfig = staffId == null &&
          (type == 'working' || type == 'holiday');
      final isStaffWorking = staffId != null && type == 'working';

      if (isShopConfig || isStaffWorking || isGeneratedStaffOff) {
        generatedIds.add(row['id'].toString());
      }
    }

    if (generatedIds.isNotEmpty) {
      await _authService.client
          .from('availability')
          .delete()
          .eq('shop_id', shopId)
          .inFilter('id', generatedIds);
    }

    if (isHoliday) {
      await _authService.client.from('availability').insert({
        'shop_id': shopId,
        'staff_id': null,
        'date': dateText,
        'day_of_week': null,
        'type': 'holiday',
        'start_time': null,
        'end_time': null,
        'reason': reason!.trim(),
        'status': true,
      });
      return;
    }

    await _authService.client.from('availability').insert({
      'shop_id': shopId,
      'staff_id': null,
      'date': dateText,
      'day_of_week': null,
      'type': 'working',
      'start_time': startTime,
      'end_time': endTime,
      'reason': null,
      'status': true,
    });

    final rows = <Map<String, dynamic>>[];
    staffStatus.forEach((staffId, enabled) {
      if (enabled) {
        rows.add({
          'shop_id': shopId,
          'staff_id': staffId,
          'date': dateText,
          'day_of_week': null,
          'type': 'working',
          'start_time': startTime,
          'end_time': endTime,
          'reason': null,
          'status': true,
        });
      } else {
        // Active leave is important: the shared availability RPC already
        // excludes leave records, so an OFF staff member cannot fall back
        // to weekly working hours.
        rows.add({
          'shop_id': shopId,
          'staff_id': staffId,
          'date': dateText,
          'day_of_week': null,
          'type': 'leave',
          'start_time': null,
          'end_time': null,
          'reason': 'Day configuration: staff off',
          'status': true,
        });
      }
    });

    if (rows.isNotEmpty) {
      await _authService.client.from('availability').insert(rows);
    }
  }

  Future<String> getManagementShopId() async {
    final user = _authService.currentUser;

    if (user == null) {
      throw Exception(
        'You are not logged in.',
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

    final shopId =
        profile['shop_id']?.toString();

    if (role != 'owner' &&
        role != 'manager') {
      throw Exception(
        'You are not authorized to manage availability.',
      );
    }

    if (shopId == null ||
        shopId.isEmpty ||
        shopId == 'null') {
      throw Exception(
        'No shop is assigned to this account.',
      );
    }

    return shopId;
  }

  // ============================================================
  // GET AVAILABILITY FOR DATE
  // ============================================================

  Future<List<AvailabilityModel>> getForDate(
    DateTime date,
  ) async {
    final shopId =
        await getManagementShopId();

    final day =
        date.weekday % 7;

    final dateText =
        _date(date);

    final rows =
        await _authService.client
            .from('availability')
            .select()
            .eq(
              'shop_id',
              shopId,
            )
            .or(
              'date.eq.$dateText,day_of_week.eq.$day',
            )
            .order(
              'status',
              ascending: false,
            )
            .order(
              'start_time',
            );

    return _map(rows);
  }

  // ============================================================
  // GET ALL ACTIVE
  // ============================================================

  Future<List<AvailabilityModel>>
      getAllActive() async {
    final shopId =
        await getManagementShopId();

    final rows =
        await _authService.client
            .from('availability')
            .select()
            .eq(
              'shop_id',
              shopId,
            )
            .order(
              'status',
              ascending: false,
            )
            .order(
              'date',
            )
            .order(
              'day_of_week',
            )
            .order(
              'start_time',
            );

    return _map(rows);
  }

  // ============================================================
  // GET ACTIVE STAFF
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getStaff() async {
    final shopId =
        await getManagementShopId();

    final rows =
        await _authService.client
            .from('staff')
            .select(
              'id,name,role,status',
            )
            .eq(
              'shop_id',
              shopId,
            )
            .eq(
              'status',
              true,
            )
            .order(
              'name',
            );

    return (rows as List)
        .map(
          (e) =>
              Map<String, dynamic>.from(
            e as Map,
          ),
        )
        .toList();
  }

  // ============================================================
  // CREATE AVAILABILITY
  // ============================================================

  Future<AvailabilityModel> create({
    String? staffId,
    DateTime? date,
    int? dayOfWeek,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
    bool status = true,
  }) async {
    final shopId =
        await getManagementShopId();

    _validateInput(
      date: date,
      dayOfWeek: dayOfWeek,
      type: type,
      startTime: startTime,
      endTime: endTime,
    );

    await _ensureNoConflict(
      shopId: shopId,
      staffId: staffId,
      date: date,
      dayOfWeek: dayOfWeek,
      type: type,
      startTime: startTime,
      endTime: endTime,
    );

    final row =
        await _authService.client
            .from('availability')
            .insert({
      'shop_id': shopId,
      'staff_id': staffId,
      'date':
          date == null
              ? null
              : _date(date),
      'day_of_week': dayOfWeek,
      'type': type,
      'start_time': startTime,
      'end_time': endTime,
      'reason': _nullable(reason),
      'status': status,
    })
            .select()
            .single();

    return AvailabilityModel.fromMap(
      Map<String, dynamic>.from(
        row,
      ),
    );
  }

  // ============================================================
  // UPDATE AVAILABILITY
  // ============================================================

  Future<AvailabilityModel> update({
    required String id,
    String? staffId,
    DateTime? date,
    int? dayOfWeek,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
    required bool status,
  }) async {
    final shopId =
        await getManagementShopId();

    _validateInput(
      date: date,
      dayOfWeek: dayOfWeek,
      type: type,
      startTime: startTime,
      endTime: endTime,
    );

    await _ensureNoConflict(
      shopId: shopId,
      staffId: staffId,
      date: date,
      dayOfWeek: dayOfWeek,
      type: type,
      startTime: startTime,
      endTime: endTime,
      excludeId: id,
    );

    final row =
        await _authService.client
            .from('availability')
            .update({
      'staff_id': staffId,
      'date':
          date == null
              ? null
              : _date(date),
      'day_of_week': dayOfWeek,
      'type': type,
      'start_time': startTime,
      'end_time': endTime,
      'reason': _nullable(reason),
      'status': status,
    })
            .eq(
              'id',
              id,
            )
            .eq(
              'shop_id',
              shopId,
            )
            .select()
            .maybeSingle();

    if (row == null) {
      throw Exception(
        'Availability record not found or access denied.',
      );
    }

    return AvailabilityModel.fromMap(
      Map<String, dynamic>.from(
        row,
      ),
    );
  }

  // ============================================================
  // SET STATUS
  // ============================================================

  Future<void> setStatus(
    String id,
    bool status,
  ) async {
    final shopId =
        await getManagementShopId();

    final rows =
        await _authService.client
            .from('availability')
            .update({
              'status': status,
            })
            .eq(
              'id',
              id,
            )
            .eq(
              'shop_id',
              shopId,
            )
            .select(
              'id',
            );

    if ((rows as List).isEmpty) {
      throw Exception(
        'Availability record not found.',
      );
    }
  }

  // ============================================================
  // URGENT BOOKING AVAILABILITY
  // ============================================================
  //
  // This method is used by:
  //
  // features/urgent_booking/time/
  //
  // It:
  //
  // 1. Gets shop availability.
  // 2. Gets staff availability.
  // 3. Uses date-specific records when applicable.
  // 4. Falls back to weekly records.
  // 5. Removes breaks.
  // 6. Removes leave.
  // 7. Removes holidays.
  // 8. Intersects shop and staff working windows.
  // 9. Generates dynamic 15-minute starting times.
  //
  // It DOES NOT create permanent slot records.
  //
  // ============================================================

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
        await _authService.client.rpc(
      'calculate_urgent_availability',
      params: {
        'p_shop_id': shopId,
        'p_staff_id': staffId,
        'p_booking_date': _date(date),
        'p_duration_minutes': durationMinutes,
      },
    );

    if (response == null) {
      return <String>[];
    }

    final rows = List<Map<String, dynamic>>.from(
      response as List,
    );

    final times = rows
        .map(
          (row) => row['start_time']?.toString(),
        )
        .whereType<String>()
        .map(
          (time) =>
              time.length >= 5
                  ? time.substring(0, 5)
                  : time,
        )
        .toList();

    times.sort();

    return times;
  }

  // ============================================================
  // WORKING RECORDS
  // ============================================================

  List<Map<String, dynamic>>
      _workingRecords(
    List<Map<String, dynamic>>
        dateRecords,
    List<Map<String, dynamic>>
        weeklyRecords, {
    required String? staffId,
  }) {
    final dateMatches =
        dateRecords.where(
      (record) {
        final recordStaffId =
            record['staff_id']
                ?.toString();

        final type =
            record['type']
                ?.toString();

        return recordStaffId ==
                staffId &&
            type == 'working';
      },
    ).toList();

    // ==========================================================
    // DATE-SPECIFIC WORKING CONFIGURATION
    // OVERRIDES WEEKLY WORKING CONFIGURATION
    // ==========================================================

    if (dateMatches.isNotEmpty) {
      return dateMatches;
    }

    return weeklyRecords.where(
      (record) {
        final recordStaffId =
            record['staff_id']
                ?.toString();

        final type =
            record['type']
                ?.toString();

        return recordStaffId ==
                staffId &&
            type == 'working';
      },
    ).toList();
  }

  // ============================================================
  // BLOCKING RECORDS
  // ============================================================
  //
  // Break, leave and holiday records
  // are converted into TimeWindow objects.
  //
  // Holiday blocks the complete day.
  //
  // ============================================================

  List<_TimeWindow>
      _blockingRecords(
    List<Map<String, dynamic>>
        dateRecords,
    List<Map<String, dynamic>>
        weeklyRecords, {
    required String? staffId,
  }) {
    final result =
        <_TimeWindow>[];

    // ==========================================================
    // DATE-SPECIFIC BLOCKS
    // ==========================================================

    for (final record
        in dateRecords) {
      _addBlockingRecord(
        result,
        record,
        staffId,
      );
    }

    // ==========================================================
    // WEEKLY BLOCKS
    // ==========================================================

    for (final record
        in weeklyRecords) {
      _addBlockingRecord(
        result,
        record,
        staffId,
      );
    }

    return _mergeTimeWindows(
      result,
    );
  }

  // ============================================================
  // ADD BLOCKING RECORD
  // ============================================================

  void _addBlockingRecord(
    List<_TimeWindow> result,
    Map<String, dynamic> record,
    String? staffId,
  ) {
    final recordStaffId =
        record['staff_id']
            ?.toString();

    if (recordStaffId !=
        staffId) {
      return;
    }

    final type =
        record['type']
            ?.toString();

    // ==========================================================
    // HOLIDAY
    // ==========================================================

    if (type == 'holiday') {
      result.add(
        const _TimeWindow(
          start: 0,
          end: 24 * 60,
        ),
      );

      return;
    }

    // ==========================================================
    // BREAK / LEAVE
    // ==========================================================

    if (type != 'break' &&
        type != 'leave') {
      return;
    }

    final start =
        _timeToMinutes(
      record['start_time'],
    );

    final end =
        _timeToMinutes(
      record['end_time'],
    );

    if (start == null ||
        end == null) {
      return;
    }

    if (end <= start) {
      return;
    }

    result.add(
      _TimeWindow(
        start: start,
        end: end,
      ),
    );
  }

  // ============================================================
  // MERGE WORKING WINDOWS
  // ============================================================

  List<_TimeWindow> _mergeWindows(
    List<Map<String, dynamic>>
        records,
  ) {
    final windows =
        <_TimeWindow>[];

    for (final record
        in records) {
      final start =
          _timeToMinutes(
        record['start_time'],
      );

      final end =
          _timeToMinutes(
        record['end_time'],
      );

      if (start == null ||
          end == null) {
        continue;
      }

      if (end <= start) {
        continue;
      }

      windows.add(
        _TimeWindow(
          start: start,
          end: end,
        ),
      );
    }

    return _mergeTimeWindows(
      windows,
    );
  }

  // ============================================================
  // INTERSECT WINDOWS
  // ============================================================

  List<_TimeWindow>
      _intersectWindows(
    List<_TimeWindow> first,
    List<_TimeWindow> second,
  ) {
    final result =
        <_TimeWindow>[];

    for (final a in first) {
      for (final b in second) {
        final start =
            a.start > b.start
                ? a.start
                : b.start;

        final end =
            a.end < b.end
                ? a.end
                : b.end;

        if (start < end) {
          result.add(
            _TimeWindow(
              start: start,
              end: end,
            ),
          );
        }
      }
    }

    return _mergeTimeWindows(
      result,
    );
  }

  // ============================================================
  // SUBTRACT BLOCKED WINDOWS
  // ============================================================

  List<_TimeWindow>
      _subtractBlockedWindows(
    List<_TimeWindow> available,
    List<_TimeWindow> blocked,
  ) {
    var result =
        List<_TimeWindow>.from(
      available,
    );

    for (final block
        in blocked) {
      final next =
          <_TimeWindow>[];

      for (final window
          in result) {
        // ======================================================
        // NO OVERLAP
        // ======================================================

        if (block.end <=
                window.start ||
            block.start >=
                window.end) {
          next.add(window);

          continue;
        }

        // ======================================================
        // BLOCK REMOVES BEGINNING
        // ======================================================

        if (block.start >
            window.start) {
          next.add(
            _TimeWindow(
              start: window.start,
              end: block.start,
            ),
          );
        }

        // ======================================================
        // BLOCK REMOVES ENDING
        // ======================================================

        if (block.end <
            window.end) {
          next.add(
            _TimeWindow(
              start: block.end,
              end: window.end,
            ),
          );
        }
      }

      result = next;
    }

    return result
        .where(
          (window) =>
              window.start <
              window.end,
        )
        .toList();
  }

  // ============================================================
  // MERGE TIME WINDOWS
  // ============================================================

  List<_TimeWindow>
      _mergeTimeWindows(
    List<_TimeWindow> windows,
  ) {
    if (windows.isEmpty) {
      return [];
    }

    final sorted =
        List<_TimeWindow>.from(
      windows,
    )..sort(
        (a, b) =>
            a.start.compareTo(
          b.start,
        ),
      );

    final merged =
        <_TimeWindow>[];

    var current =
        sorted.first;

    for (var i = 1;
        i < sorted.length;
        i++) {
      final next =
          sorted[i];

      if (next.start <=
          current.end) {
        current =
            _TimeWindow(
          start: current.start,
          end: current.end >
                  next.end
              ? current.end
              : next.end,
        );
      } else {
        merged.add(
          current,
        );

        current = next;
      }
    }

    merged.add(
      current,
    );

    return merged;
  }

  // ============================================================
  // GENERATE 15-MINUTE START TIMES
  // ============================================================

  List<String>
      _generateStartTimes(
    List<_TimeWindow> windows,
    int durationMinutes,
  ) {
    final result =
        <String>[];

    const intervalMinutes =
        15;

    for (final window
        in windows) {
      var current =
          window.start;

      while (
          current +
                  durationMinutes <=
              window.end) {
        result.add(
          _minutesToTime(
            current,
          ),
        );

        current +=
            intervalMinutes;
      }
    }

    return result;
  }

  // ============================================================
  // TIME → MINUTES
  // ============================================================

  int? _timeToMinutes(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString();

    if (text.length < 5) {
      return null;
    }

    final parts =
        text
            .substring(0, 5)
            .split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour =
        int.tryParse(
      parts[0],
    );

    final minute =
        int.tryParse(
      parts[1],
    );

    if (hour == null ||
        minute == null) {
      return null;
    }

    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return hour * 60 +
        minute;
  }

  // ============================================================
  // MINUTES → TIME
  // ============================================================

  String _minutesToTime(
    int minutes,
  ) {
    final hour =
        minutes ~/ 60;

    final minute =
        minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }

  // ============================================================
  // CONFLICT CHECK
  // ============================================================

  Future<void>
      _ensureNoConflict({
    required String shopId,
    String? staffId,
    DateTime? date,
    int? dayOfWeek,
    required String type,
    String? startTime,
    String? endTime,
    String? excludeId,
  }) async {
    // ==========================================================
    // SHOP HOLIDAY
    // ==========================================================

    if (type == 'holiday') {
      final rows =
          await _authService.client
              .from('availability')
              .select('id')
              .eq(
                'shop_id',
                shopId,
              )
              .eq(
                'status',
                true,
              )
              .eq(
                'type',
                'holiday',
              )
              .isFilter(
                'staff_id',
                null,
              )
              .eq(
                'date',
                _date(date!),
              );

      if ((rows as List)
          .where(
            (row) =>
                row['id']
                    ?.toString() !=
                excludeId,
          )
          .isNotEmpty) {
        throw Exception(
          'An active shop holiday already exists for this date.',
        );
      }

      return;
    }

    // ==========================================================
    // WORKING / BREAK / LEAVE
    // ==========================================================

    if (![
      'working',
      'break',
      'leave',
    ].contains(type)) {
      return;
    }

    final query =
        _authService.client
            .from('availability')
            .select(
              'id,staff_id,date,day_of_week,type,start_time,end_time,status',
            )
            .eq(
              'shop_id',
              shopId,
            )
            .eq(
              'status',
              true,
            )
            .eq(
              'type',
              type,
            );

    final rows =
        await query;

    final records =
        (rows as List)
            .map(
              (e) =>
                  AvailabilityModel.fromMap(
                Map<String, dynamic>.from(
                  e as Map,
                ),
              ),
            )
            .where(
              (existing) =>
                  existing.id !=
                  excludeId,
            )
            .where(
              (existing) =>
                  existing.staffId ==
                  staffId,
            )
            .where(
              (existing) =>
                  _sameScope(
                existing,
                date,
                dayOfWeek,
              ),
            )
            .where(
              (existing) =>
                  _overlaps(
                existing.startTime,
                existing.endTime,
                startTime,
                endTime,
              ),
            )
            .toList();

    if (records.isNotEmpty) {
      throw Exception(
        'This $type overlaps an existing active $type configuration.',
      );
    }
  }

  // ============================================================
  // SAME SCOPE
  // ============================================================

  bool _sameScope(
    AvailabilityModel item,
    DateTime? date,
    int? dayOfWeek,
  ) {
    if (date != null) {
      return item.date != null &&
          _date(item.date!) ==
              _date(date);
    }

    return item.date == null &&
        item.dayOfWeek ==
            dayOfWeek;
  }

  // ============================================================
  // OVERLAP CHECK
  // ============================================================

  bool _overlaps(
    String? aStart,
    String? aEnd,
    String? bStart,
    String? bEnd,
  ) {
    if (aStart == null ||
        aEnd == null ||
        bStart == null ||
        bEnd == null) {
      return false;
    }

    final a1 =
        _minutes(aStart);

    final a2 =
        _minutes(aEnd);

    final b1 =
        _minutes(bStart);

    final b2 =
        _minutes(bEnd);

    return a1 < b2 &&
        a2 > b1;
  }

  // ============================================================
  // VALIDATE INPUT
  // ============================================================

  void _validateInput({
    required DateTime? date,
    required int? dayOfWeek,
    required String type,
    required String? startTime,
    required String? endTime,
  }) {
    if (![
      'working',
      'break',
      'leave',
      'holiday',
    ].contains(type)) {
      throw Exception(
        'Invalid availability type.',
      );
    }

    if (date != null &&
        dayOfWeek != null) {
      throw Exception(
        'A configuration must be either date-specific or weekly, not both.',
      );
    }

    if (date == null &&
        dayOfWeek == null) {
      throw Exception(
        'Select a date or a weekly day.',
      );
    }

    if (dayOfWeek != null &&
        (dayOfWeek < 0 ||
            dayOfWeek > 6)) {
      throw Exception(
        'Invalid day of week.',
      );
    }

    // ==========================================================
    // HOLIDAY
    // ==========================================================

    if (type == 'holiday') {
      if (date == null ||
          dayOfWeek != null) {
        throw Exception(
          'A shop holiday must use a specific date.',
        );
      }

      if (startTime != null ||
          endTime != null) {
        throw Exception(
          'A holiday does not have a time range.',
        );
      }

      return;
    }

    // ==========================================================
    // TIME BASED TYPES
    // ==========================================================

    if (startTime == null ||
        endTime == null) {
      throw Exception(
        'Start time and end time are required.',
      );
    }

    if (_minutes(startTime) >=
        _minutes(endTime)) {
      throw Exception(
        'End time must be after start time.',
      );
    }
  }

  // ============================================================
  // STRING TIME → MINUTES
  // ============================================================

  int _minutes(
    String value,
  ) {
    final parts =
        value.split(':');

    if (parts.length < 2) {
      throw Exception(
        'Invalid time format.',
      );
    }

    final hour =
        int.tryParse(
      parts[0],
    );

    final minute =
        int.tryParse(
      parts[1],
    );

    if (hour == null ||
        minute == null) {
      throw Exception(
        'Invalid time format.',
      );
    }

    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw Exception(
        'Invalid time value.',
      );
    }

    return hour * 60 +
        minute;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _date(
    DateTime date,
  ) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullable(
    String? value,
  ) {
    final trimmed =
        value?.trim();

    return trimmed == null ||
            trimmed.isEmpty
        ? null
        : trimmed;
  }

  // ============================================================
  // MAP
  // ============================================================

  List<AvailabilityModel> _map(
    dynamic rows,
  ) =>
      (rows as List)
          .map(
            (e) =>
                AvailabilityModel.fromMap(
              Map<String, dynamic>.from(
                e as Map,
              ),
            ),
          )
          .toList();
}

// ================================================================
// TIME WINDOW
// ================================================================

class _TimeWindow {
  const _TimeWindow({
    required this.start,
    required this.end,
  });

  final int start;

  final int end;
}

