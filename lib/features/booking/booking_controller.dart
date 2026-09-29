import 'package:flutter/foundation.dart';

import '../../models/service_model.dart';
import '../../models/shop_model.dart';
import '../../models/staff_model.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/staff_repository.dart';

/// Shared state for the customer booking flow.
///
/// This controller intentionally does not create appointments. It only carries
/// the selections that later booking steps (staff, time and review) will use.
class BookingController extends ChangeNotifier {
  BookingController({
    ServiceRepository? serviceRepository,
    StaffRepository? staffRepository,
    ShopModel? initialShop,
  })  : _serviceRepository = serviceRepository ?? ServiceRepository(),
        _staffRepository = staffRepository ?? StaffRepository(),
        _selectedShop = initialShop;

  final ServiceRepository _serviceRepository;
  final StaffRepository _staffRepository;

  ShopModel? _selectedShop;
  DateTime? _selectedDate;
  List<ServiceModel> _availableServices = [];
  final List<ServiceModel> _selectedServices = [];
  bool _isLoadingServices = false;
  String? _servicesErrorMessage;

  List<StaffModel> _availableStaff = [];
  StaffModel? _selectedStaff;
  bool _isLoadingStaff = false;
  String? _staffErrorMessage;

  String? _selectedTime;

  ShopModel? get selectedShop => _selectedShop;
  DateTime? get selectedDate => _selectedDate;
  List<ServiceModel> get availableServices => List.unmodifiable(_availableServices);
  List<ServiceModel> get selectedServices => List.unmodifiable(_selectedServices);
  bool get isLoadingServices => _isLoadingServices;
  String? get servicesErrorMessage => _servicesErrorMessage;
  List<StaffModel> get availableStaff => List.unmodifiable(_availableStaff);
  StaffModel? get selectedStaff => _selectedStaff;
  bool get isLoadingStaff => _isLoadingStaff;
  String? get staffErrorMessage => _staffErrorMessage;
  String? get selectedTime => _selectedTime;

  int get totalDurationMinutes => _selectedServices.fold(
        0,
        (total, service) => total + service.durationMinutes,
      );

  double get totalPrice => _selectedServices.fold(
        0.0,
        (total, service) => total + service.price,
      );

  /// True when any selected service must go through the request flow.
  bool get requiresRequestApproval =>
      _selectedServices.any((service) => service.request);

  Map<String, List<ServiceModel>> get servicesByCategory {
    final grouped = <String, List<ServiceModel>>{};
    for (final service in _availableServices) {
      final category = service.categoryName.trim().isEmpty
          ? 'Other Services'
          : service.categoryName.trim();
      grouped.putIfAbsent(category, () => []).add(service);
    }
    return grouped;
  }

  void selectShop(ShopModel shop) {
    final changedShop = _selectedShop?.id != shop.id;
    _selectedShop = shop;

    // Services always belong to one shop. A shop change invalidates old services.
    if (changedShop) {
      _selectedServices.clear();
      _availableServices = [];
      _servicesErrorMessage = null;
      _availableStaff = [];
      _selectedStaff = null;
      _selectedTime = null;
      _staffErrorMessage = null;
    }
    notifyListeners();
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate != normalized) {
      _selectedTime = null;
    }
    _selectedDate = normalized;
    notifyListeners();
  }

  Future<void> loadServices() async {
    final shopId = _selectedShop?.id;
    if (shopId == null || shopId.isEmpty) return;
    if (_isLoadingServices) return;

    _isLoadingServices = true;
    _servicesErrorMessage = null;
    notifyListeners();

    try {
      final loaded = await _serviceRepository.loadActiveServicesForShop(shopId);
      _availableServices = loaded;

      // Keep only selections that still belong to the active service result.
      final activeIds = loaded.map((service) => service.id).toSet();
      _selectedServices.removeWhere(
        (service) => !activeIds.contains(service.id),
      );
    } catch (error) {
      _servicesErrorMessage = error.toString();
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }


  Future<void> loadStaff() async {
    final shopId = _selectedShop?.id;
    if (shopId == null || shopId.isEmpty) return;
    if (_isLoadingStaff) return;

    _isLoadingStaff = true;
    _staffErrorMessage = null;
    notifyListeners();

    try {
      final loaded = await _staffRepository.loadActiveStaffForShop(shopId);
      _availableStaff = loaded;
      final selectedId = _selectedStaff?.id;
      if (selectedId != null && !loaded.any((staff) => staff.id == selectedId)) {
        _selectedStaff = null;
      }
    } catch (error) {
      _staffErrorMessage = error.toString();
    } finally {
      _isLoadingStaff = false;
      notifyListeners();
    }
  }

  void selectStaff(StaffModel staff) {
    if (staff.shopId != _selectedShop?.id) return;
    if (_selectedStaff?.id != staff.id) {
      _selectedTime = null;
    }
    _selectedStaff = staff;
    notifyListeners();
  }

  void selectTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }

  void clearTime() {
    if (_selectedTime == null) return;
    _selectedTime = null;
    notifyListeners();
  }

  void clearStaff() {
    if (_selectedStaff == null) return;
    _selectedStaff = null;
    _selectedTime = null;
    notifyListeners();
  }

  bool isSelected(ServiceModel service) =>
      _selectedServices.any((item) => item.id == service.id);

  void toggleService(ServiceModel service) {
    final index = _selectedServices.indexWhere((item) => item.id == service.id);
    if (index >= 0) {
      _selectedServices.removeAt(index);
    } else {
      _selectedServices.add(service);
    }
    _selectedTime = null;
    notifyListeners();
  }

  void clearServices() {
    if (_selectedServices.isEmpty) return;
    _selectedServices.clear();
    _selectedTime = null;
    notifyListeners();
  }

  void reset() {
    _selectedShop = null;
    _selectedDate = null;
    _availableServices = [];
    _selectedServices.clear();
    _servicesErrorMessage = null;
    _isLoadingServices = false;
    _availableStaff = [];
    _selectedStaff = null;
    _selectedTime = null;
    _staffErrorMessage = null;
    _isLoadingStaff = false;
    notifyListeners();
  }
}
