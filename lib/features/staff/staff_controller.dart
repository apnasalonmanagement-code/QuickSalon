import 'package:flutter/foundation.dart';

import '../../repositories/staff_repository.dart';

class StaffController extends ChangeNotifier {
  StaffController({StaffRepository? repository})
      : _repository = repository ?? StaffRepository();

  final StaffRepository _repository;

  List<Map<String, dynamic>> staff = [];
  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      staff = await _repository.getStaff();
    } catch (e) {
      errorMessage = _clean(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add({
    required String name,
    required String phone,
    required String role,
    required String imageUrl,
    required bool status,
  }) async {
    final validation = _validate(name, phone, role);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createStaff(
        name: name,
        phone: phone,
        role: role,
        imageUrl: imageUrl,
        status: status,
      );
      staff = [...staff, created]..sort(_sortByName);
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    required String name,
    required String phone,
    required String role,
    required String imageUrl,
    required bool status,
  }) async {
    final validation = _validate(name, phone, role);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateStaff(
        staffId: id,
        name: name,
        phone: phone,
        role: role,
        imageUrl: imageUrl,
        status: status,
      );
      final index = staff.indexWhere((item) => item['id']?.toString() == id);
      if (index >= 0) {
        final copy = [...staff];
        copy[index] = updated;
        copy.sort(_sortByName);
        staff = copy;
      }
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> setStatus(String id, bool status) async {
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.setStatus(
        staffId: id,
        status: status,
      );
      final index = staff.indexWhere((item) => item['id']?.toString() == id);
      if (index >= 0) {
        final copy = [...staff];
        copy[index] = updated;
        staff = copy;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteStaff(id);
      staff = staff.where((item) => item['id']?.toString() != id).toList();
      return true;
    } catch (e) {
      errorMessage = _clean(e);
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  String? _validate(String name, String phone, String role) {
    if (name.trim().isEmpty) return 'Staff name is required.';
    if (name.trim().length < 2) return 'Staff name must contain at least 2 characters.';
    if (role.trim().isEmpty) return 'Staff role is required.';
    if (phone.trim().isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) return 'Enter a valid phone number.';
    }
    return null;
  }

  int _sortByName(Map<String, dynamic> a, Map<String, dynamic> b) =>
      (a['name']?.toString() ?? '').toLowerCase().compareTo(
            (b['name']?.toString() ?? '').toLowerCase(),
          );

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
