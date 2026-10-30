import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/appointment_repository.dart';

class UrgentReviewController extends ChangeNotifier {
  UrgentReviewController({
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.selectedTime,
    required this.totalDuration,
    required this.totalPrice,
    AppointmentRepository? appointmentRepository,
  }) : _appointmentRepository =
            appointmentRepository ?? AppointmentRepository() {
    loadShop();
  }

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic> selectedStaff;
  final String selectedTime;
  final int totalDuration;
  final double totalPrice;
  final AppointmentRepository _appointmentRepository;

  final SupabaseClient _supabase = Supabase.instance.client;

  String _shopName = 'Shop';
  bool _isLoadingShop = false;
  bool _isBooking = false;
  String? _errorMessage;

  String get shopName => _shopName;
  bool get isLoadingShop => _isLoadingShop;
  bool get isBooking => _isBooking;
  String? get errorMessage => _errorMessage;

  Future<void> loadShop() async {
    _isLoadingShop = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('shops')
          .select('id, shop_name')
          .eq('id', shopId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Shop not found.');
      }

      _shopName = response['shop_name']?.toString() ?? 'Shop';
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _isLoadingShop = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking() async {
    _isBooking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final serviceIds = selectedServices
          .map((service) => service['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (serviceIds.isEmpty) {
        throw Exception('No services selected.');
      }

      final staffId = selectedStaff['id']?.toString();
      if (staffId == null || staffId.isEmpty) {
        throw Exception('No staff member selected.');
      }

      await _appointmentRepository.createUrgentBooking(
        shopId: shopId,
        staffId: staffId,
        customerName: customerName,
        customerPhone: customerPhone,
        bookingDate: bookingDate,
        startTime: selectedTime,
        serviceIds: serviceIds,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  String dateText() =>
      '${bookingDate.day.toString().padLeft(2, '0')}/'
      '${bookingDate.month.toString().padLeft(2, '0')}/'
      '${bookingDate.year}';

  String timeText() {
    final parts = selectedTime.split(':');
    if (parts.length < 2) return selectedTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $suffix';
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
}
