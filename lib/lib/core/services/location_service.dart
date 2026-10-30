import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position> getCurrentLocation() async {
    // ----------------------------------------------------------
    // Check whether location service is enabled
    // ----------------------------------------------------------

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location service is disabled. Please turn on GPS/location services.',
      );
    }

    // ----------------------------------------------------------
    // Check permission
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    // ----------------------------------------------------------
    // Request permission
    // ----------------------------------------------------------

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }
    }

    // ----------------------------------------------------------
    // Permanently denied
    // ----------------------------------------------------------

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it from Android Settings.',
      );
    }

    // ----------------------------------------------------------
    // Get current GPS position
    // ----------------------------------------------------------

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}