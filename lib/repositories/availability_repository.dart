import '../core/services/availability_service.dart';

class AvailabilityRepository {
  AvailabilityRepository({AvailabilityService? availabilityService})
      : _availabilityService = availabilityService ?? AvailabilityService();

  final AvailabilityService _availabilityService;

  /// Delegates to the database availability engine.
  ///
  /// No permanent slots are created and no second client-side algorithm exists.
  Future<List<String>> getCustomerStartTimes({
    required String shopId,
    required String staffId,
    required DateTime date,
    required int durationMinutes,
  }) {
    return _availabilityService.getCustomerStartTimes(
      shopId: shopId,
      staffId: staffId,
      date: date,
      durationMinutes: durationMinutes,
    );
  }
}
