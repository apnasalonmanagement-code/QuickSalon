import 'package:flutter/foundation.dart';

import '../../../core/services/auth_service.dart';

class UrgentDateController extends ChangeNotifier {
  UrgentDateController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _shopId;
  String _customerName = '';
  String _customerPhone = '';
  String? _errorMessage;
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  String? get shopId => _shopId;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No authenticated management user found.');
      final profile = await _authService.getProfile(user.id);
      if (profile == null) throw Exception('Management profile not found.');
      final role = profile['role']?.toString();
      if (role != 'owner' && role != 'manager') {
        throw Exception('You are not authorized to create bookings.');
      }
      final shopId = profile['shop_id']?.toString();
      if (shopId == null || shopId.isEmpty) throw Exception('No shop is assigned to this account.');
      _shopId = shopId;
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCustomerName(String value) { _customerName = value; notifyListeners(); }
  void setCustomerPhone(String value) { _customerPhone = value; notifyListeners(); }
  bool get canContinue => _shopId != null && _customerName.trim().isNotEmpty;

  void selectDate(DateTime date) { _selectedDate = _dateOnly(date); notifyListeners(); }
  bool isToday(DateTime date) => _sameDate(date, DateTime.now());
  bool isTomorrow(DateTime date) => _sameDate(date, DateTime.now().add(const Duration(days: 1)));
  bool isDayAfterTomorrow(DateTime date) => _sameDate(date, DateTime.now().add(const Duration(days: 2)));
  String dateLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isDayAfterTomorrow(date)) return 'Day After Tomorrow';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  static bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
}
