import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/service_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/staff_model.dart';
import '../../../repositories/appointment_repository.dart';

class BookingReviewController extends ChangeNotifier {
  BookingReviewController({
    required this.shop,
    required this.bookingDate,
    required this.selectedServices,
    required this.selectedStaff,
    required this.selectedTime,
    AppointmentRepository? appointmentRepository,
    SupabaseClient? client,
  })  : _appointmentRepository =
            appointmentRepository ?? AppointmentRepository(),
        _client = client ?? Supabase.instance.client {
    loadCustomer();
  }

  final ShopModel shop;
  final DateTime bookingDate;
  final List<ServiceModel> selectedServices;
  final StaffModel selectedStaff;
  final String selectedTime;
  final AppointmentRepository _appointmentRepository;
  final SupabaseClient _client;

  bool _isLoadingCustomer = false;
  bool _isBooking = false;
  String? _errorMessage;
  String _customerName = 'Customer';
  String? _createdBookingStatus;

  bool get isLoadingCustomer => _isLoadingCustomer;
  bool get isBooking => _isBooking;
  String? get errorMessage => _errorMessage;
  String get customerName => _customerName;
  String? get createdBookingStatus => _createdBookingStatus;

  int get totalDuration => selectedServices.fold(
        0,
        (total, service) => total + service.durationMinutes,
      );

  double get totalPrice => selectedServices.fold(
        0.0,
        (total, service) => total + service.price,
      );

  bool get requiresRequestApproval =>
      selectedServices.any((service) => service.request);

  String get expectedStatus =>
      requiresRequestApproval ? 'pending' : 'confirmed';

  String get endTime => _addMinutes(selectedTime, totalDuration);

  Future<void> loadCustomer() async {
    _isLoadingCustomer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Your session has expired. Please sign in again.');
      }

      final response = await _client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      final name = response?['name']?.toString().trim();
      _customerName = name != null && name.isNotEmpty
          ? name
          : (user.email?.trim().isNotEmpty == true
              ? user.email!.trim()
              : 'Customer');
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _isLoadingCustomer = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking() async {
    if (_isBooking) return false;

    _isBooking = true;
    _errorMessage = null;
    _createdBookingStatus = null;
    notifyListeners();

    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;
      if (user == null || session == null) {
        throw Exception('Your session has expired. Please sign in again.');
      }

      if (selectedServices.isEmpty) {
        throw Exception('No services selected.');
      }
      if (totalDuration <= 0) {
        throw Exception('Invalid service duration.');
      }
      if (shop.id.trim().isEmpty || selectedStaff.id.trim().isEmpty) {
        throw Exception('Booking information is incomplete.');
      }
      if (selectedTime.trim().isEmpty) {
        throw Exception('Please select an available time.');
      }

      final serviceIds = selectedServices.map((service) => service.id).toList();
      if (serviceIds.toSet().length != serviceIds.length) {
        throw Exception('Duplicate services cannot be booked.');
      }

      final appointment =
          await _appointmentRepository.createCustomerBooking(
        shopId: shop.id,
        staffId: selectedStaff.id,
        bookingDate: bookingDate,
        startTime: selectedTime,
        serviceIds: serviceIds,
      );

      _createdBookingStatus =
          appointment['status']?.toString().toLowerCase();

      if (_createdBookingStatus != 'pending' &&
          _createdBookingStatus != 'confirmed') {
        throw Exception(
          'The booking was created with an unexpected status.',
        );
      }

      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
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

  String displayTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _addMinutes(String value, int minutesToAdd) {
    final parts = value.trim().split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final total = hour * 60 + minute + minutesToAdd;
    final endHour = total ~/ 60;
    final endMinute = total % 60;
    return '${endHour.toString().padLeft(2, '0')}:'
        '${endMinute.toString().padLeft(2, '0')}:00';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
