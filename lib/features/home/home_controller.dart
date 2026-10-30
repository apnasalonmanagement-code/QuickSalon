import 'package:flutter/foundation.dart';

import '../../models/profile_model.dart';
import '../../models/shop_model.dart';
import '../../models/user_address_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/shop_repository.dart';
import '../../core/constants/shop_constants.dart';
import '../../core/services/location_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AuthRepository? authRepository,
    ShopRepository? shopRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _shopRepository = shopRepository ?? ShopRepository();

  final AuthRepository _authRepository;
  final ShopRepository _shopRepository;

  static const List<String> availableCities =
      ShopConstants.supportedCities;

  ProfileModel? profile;
  List<ShopModel> _allShops = <ShopModel>[];

  bool isLoading = false;
  bool isLocationLoading = false;

  String? errorMessage;
  String? locationErrorMessage;

  String _searchQuery = '';
  String _selectedCity = 'Karad';
  String _selectedAudience = 'male';

  double? _latitude;
  double? _longitude;

  bool _usingCurrentLocation = false;
  String? _selectedAddressLabel;

  String get selectedCity => _selectedCity;
  String get selectedAudience => _selectedAudience;

  bool get usingCurrentLocation => _usingCurrentLocation;

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  String? get selectedAddressLabel => _selectedAddressLabel;

  String get locationText {
    if (_usingCurrentLocation) {
      return _selectedAddressLabel ?? 'Near you';
    }

    return _selectedCity;
  }

  List<ShopModel> get shops {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _allShops.where((shop) {
      final type = shop.shopType.trim().toLowerCase();

      final matchesAudience = _selectedAudience == 'male'
          ? (type == 'salon' || type == 'unisexsalon')
          : (type == 'parlour' || type == 'unisexsalon');

      if (!matchesAudience) {
        return false;
      }

      // If using GPS, don't restrict by city.
      // PostGIS has already sorted shops by distance.
      if (!_usingCurrentLocation) {
        final city = _selectedCity.trim().toLowerCase();

        final sameCity =
            shop.city.trim().toLowerCase() == city;

        if (!sameCity) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return shop.shopName.toLowerCase().contains(query) ||
          shop.city.toLowerCase().contains(query);
    }).toList();

    return List.unmodifiable(filtered);
  }

  Future<void> load() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final user = _authRepository.currentUser;

      if (user == null) {
        throw Exception(
          'Your session has expired. Please login again.',
        );
      }

      final results = await Future.wait<dynamic>([
        _authRepository.getProfile(user.id),
        _shopRepository.loadActiveShops(),
      ]);

      profile = results[0] as ProfileModel?;
      _allShops = results[1] as List<ShopModel>;

      // The customer's saved city is the default.
      // If it is empty or is not one of the supported home cities,
      // Karad remains the default.
      final profileCity = _canonicalCity(profile?.city);

      if (profileCity != null) {
        _selectedCity = profileCity;
      } else if (!availableCities.contains(_selectedCity)) {
        _selectedCity = 'Karad';
      }

      // Normal city-based loading remains the default.
      _usingCurrentLocation = false;
      _selectedAddressLabel = null;
      _latitude = null;
      _longitude = null;
    } catch (e) {
      errorMessage = _readableError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    if (isLocationLoading) return;

    isLocationLoading = true;
    locationErrorMessage = null;
    errorMessage = null;

    notifyListeners();

    try {
      final position =
          await LocationService.getCurrentLocation();

      _latitude = position.latitude;
      _longitude = position.longitude;

      final nearbyShops =
          await _shopRepository.loadNearbyShops(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: 10000,
      );

      _allShops = nearbyShops;

      _usingCurrentLocation = true;
      _selectedAddressLabel = null;

      // Clear city filter because GPS is now the source of location.
      _searchQuery = '';
    } catch (e) {
      locationErrorMessage = _readableError(e);
    } finally {
      isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> useSavedAddress(UserAddressModel address) async {
    if (isLocationLoading) return;

    isLocationLoading = true;
    locationErrorMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final nearbyShops = await _shopRepository.loadNearbyShops(
        latitude: address.latitude,
        longitude: address.longitude,
        radiusMeters: 10000,
      );

      _latitude = address.latitude;
      _longitude = address.longitude;
      _selectedAddressLabel = address.label;
      _allShops = nearbyShops;
      _usingCurrentLocation = true;
      _searchQuery = '';
    } catch (e) {
      locationErrorMessage = _readableError(e);
    } finally {
      isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentLocation() async {
    await useCurrentLocation();
  }

  void search(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void selectAudience(String audience) {
    if (audience != 'male' && audience != 'female') {
      return;
    }

    if (_selectedAudience == audience) {
      return;
    }

    _selectedAudience = audience;

    notifyListeners();
  }

  void selectCity(String city) {
    final canonical = _canonicalCity(city);

    if (canonical == null) {
      return;
    }

    _selectedCity = canonical;

    // City selection switches back from GPS mode.
    _usingCurrentLocation = false;
    _selectedAddressLabel = null;

    _latitude = null;
    _longitude = null;

    _searchQuery = '';

    // Reload normal city-based shops.
    load();
  }

  String? _canonicalCity(String? value) {
    final normalized = value?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final city in availableCities) {
      if (city.toLowerCase() == normalized) {
        return city;
      }
    }

    return null;
  }

  String _readableError(Object error) {
    final message =
        error.toString().replaceFirst('Exception: ', '');

    return message.isEmpty
        ? 'Unable to load shops. Please try again.'
        : message;
  }
}