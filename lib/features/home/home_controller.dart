import 'package:flutter/foundation.dart';

import '../../models/profile_model.dart';
import '../../models/shop_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/shop_repository.dart';
import '../../core/constants/shop_constants.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AuthRepository? authRepository,
    ShopRepository? shopRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _shopRepository = shopRepository ?? ShopRepository();

  final AuthRepository _authRepository;
  final ShopRepository _shopRepository;

  static const List<String> availableCities = ShopConstants.supportedCities;

  ProfileModel? profile;
  List<ShopModel> _allShops = <ShopModel>[];
  bool isLoading = false;
  String? errorMessage;
  String _searchQuery = '';
  String _selectedCity = 'Karad';
  String _selectedAudience = 'male';

  String get selectedCity => _selectedCity;
  String get selectedAudience => _selectedAudience;

  List<ShopModel> get shops {
    final query = _searchQuery.trim().toLowerCase();
    final city = _selectedCity.trim().toLowerCase();

    final filtered = _allShops.where((shop) {
      final sameCity = shop.city.trim().toLowerCase() == city;
      if (!sameCity) return false;

      final type = shop.shopType.trim().toLowerCase();
      final matchesAudience = _selectedAudience == 'male'
          ? (type == 'salon' || type == 'unisexsalon')
          : (type == 'parlour' || type == 'unisexsalon');
      if (!matchesAudience) return false;

      if (query.isEmpty) return true;
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
        throw Exception('Your session has expired. Please login again.');
      }

      final results = await Future.wait<dynamic>([
        _authRepository.getProfile(user.id),
        _shopRepository.loadActiveShops(),
      ]);

      profile = results[0] as ProfileModel?;
      _allShops = results[1] as List<ShopModel>;

      // The customer's saved city is the default. If it is empty or is not
      // one of the supported home cities, Karad remains the default.
      final profileCity = _canonicalCity(profile?.city);
      if (profileCity != null) {
        _selectedCity = profileCity;
      } else if (!availableCities.contains(_selectedCity)) {
        _selectedCity = 'Karad';
      }
    } catch (e) {
      errorMessage = _readableError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void selectAudience(String audience) {
    if (audience != 'male' && audience != 'female') return;
    if (_selectedAudience == audience) return;
    _selectedAudience = audience;
    notifyListeners();
  }

  void selectCity(String city) {
    final canonical = _canonicalCity(city);
    if (canonical == null || canonical == _selectedCity) return;

    _selectedCity = canonical;
    _searchQuery = '';
    notifyListeners();
  }

  String? _canonicalCity(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    for (final city in availableCities) {
      if (city.toLowerCase() == normalized) return city;
    }
    return null;
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Unable to load salons. Please try again.'
        : message;
  }
}
