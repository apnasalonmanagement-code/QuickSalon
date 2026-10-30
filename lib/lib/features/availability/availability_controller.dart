import 'package:flutter/foundation.dart';

import '../../models/availability_model.dart';
import '../../repositories/availability_repository.dart';

class AvailabilityController extends ChangeNotifier {
  AvailabilityController({AvailabilityRepository? repository})
      : _repository = repository ?? AvailabilityRepository();

  final AvailabilityRepository _repository;

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();
  List<AvailabilityModel> records = [];
  List<Map<String, dynamic>> staff = [];

  List<AvailabilityModel> get activeRecords =>
      records.where((e) => e.status).toList();

  List<AvailabilityModel> get shopRecords =>
      records.where((e) => e.staffId == null).toList();

  List<AvailabilityModel> get staffRecords =>
      records.where((e) => e.staffId != null).toList();

  Future<void> initialize() async {
    await loadStaff();
    await loadForDate(selectedDate);
  }

  Future<void> loadStaff() async {
    try {
      staff = await _repository.getStaff();
      notifyListeners();
    } catch (e) {
      errorMessage = _clean(e);
      notifyListeners();
    }
  }

  Future<void> loadForDate(DateTime date) async {
    selectedDate = DateTime(date.year, date.month, date.day);
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      records = await _repository.getDateConfiguration(selectedDate);
    } catch (e) {
      errorMessage = _clean(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDateConfiguration({
    required bool isHoliday,
    String? reason,
    String? startTime,
    String? endTime,
    required Map<String, bool> staffStatus,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveDateConfiguration(
        date: selectedDate,
        isHoliday: isHoliday,
        reason: reason,
        startTime: startTime,
        endTime: endTime,
        staffStatus: staffStatus,
      );
      records = await _repository.getDateConfiguration(selectedDate);
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    String? id,
    String? staffId,
    DateTime? date,
    int? dayOfWeek,
    required String type,
    String? startTime,
    String? endTime,
    String? reason,
    bool status = true,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (id == null) {
        await _repository.create(
          staffId: staffId,
          date: date,
          dayOfWeek: dayOfWeek,
          type: type,
          startTime: startTime,
          endTime: endTime,
          reason: reason,
          status: status,
        );
      } else {
        await _repository.update(
          id: id,
          staffId: staffId,
          date: date,
          dayOfWeek: dayOfWeek,
          type: type,
          startTime: startTime,
          endTime: endTime,
          reason: reason,
          status: status,
        );
      }
      records = await _repository.getDateConfiguration(selectedDate);
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setStatus(String id, bool status) async {
    try {
      await _repository.setStatus(id, status);
      records = await _repository.getDateConfiguration(selectedDate);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      notifyListeners();
      return false;
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
