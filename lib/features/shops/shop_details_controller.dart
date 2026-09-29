import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/service_model.dart';
import '../../models/staff_model.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/staff_repository.dart';

class ShopDetailsController extends ChangeNotifier {
  ShopDetailsController({
    ServiceRepository? serviceRepository,
    StaffRepository? staffRepository,
    FavoritesRepository? favoritesRepository,
    SupabaseClient? client,
  })  : _serviceRepository = serviceRepository ?? ServiceRepository(),
        _staffRepository = staffRepository ?? StaffRepository(),
        _favoritesRepository = favoritesRepository ?? FavoritesRepository(),
        _client = client ?? Supabase.instance.client;

  final ServiceRepository _serviceRepository;
  final StaffRepository _staffRepository;
  final FavoritesRepository _favoritesRepository;
  final SupabaseClient _client;

  bool isLoading = false;
  bool isFavoriteLoading = false;
  bool isFavoriteActionLoading = false;
  String? errorMessage;
  String? favoriteErrorMessage;
  List<ServiceModel> services = [];
  List<StaffModel> staff = [];
  bool isFavorite = false;

  Map<String, List<ServiceModel>> get servicesByCategory {
    final grouped = <String, List<ServiceModel>>{};
    for (final service in services) {
      final category = service.categoryName.trim().isEmpty
          ? 'Other Services'
          : service.categoryName.trim();
      grouped.putIfAbsent(category, () => []).add(service);
    }
    return grouped;
  }

  Future<void> load(String shopId) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _serviceRepository.loadActiveServicesForShop(shopId),
        _staffRepository.loadActiveStaffForShop(shopId),
      ]);

      services = results[0] as List<ServiceModel>;
      staff = results[1] as List<StaffModel>;

      // Favorites must never block the existing shop details feature.
      try {
        await loadFavoriteState(shopId, notify: false);
      } catch (_) {}
    } catch (e) {
      errorMessage = _readableError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavoriteState(String shopId, {bool notify = true}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      isFavorite = false;
      if (notify) notifyListeners();
      return;
    }
    isFavoriteLoading = true;
    favoriteErrorMessage = null;
    if (notify) notifyListeners();
    try {
      final ids = await _favoritesRepository.loadFavoriteShopIds(user.id);
      isFavorite = ids.contains(shopId);
    } catch (e) {
      favoriteErrorMessage = _readableError(e);
    } finally {
      isFavoriteLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String shopId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      favoriteErrorMessage = 'Please sign in again to manage favorites.';
      notifyListeners();
      return false;
    }
    isFavoriteActionLoading = true;
    favoriteErrorMessage = null;
    notifyListeners();
    try {
      if (isFavorite) {
        await _favoritesRepository.removeFavorite(customerId: user.id, shopId: shopId);
      } else {
        await _favoritesRepository.addFavorite(customerId: user.id, shopId: shopId);
      }
      isFavorite = !isFavorite;
      return true;
    } catch (e) {
      favoriteErrorMessage = _readableError(e);
      return false;
    } finally {
      isFavoriteActionLoading = false;
      notifyListeners();
    }
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Unable to load shop details. Please try again.'
        : message;
  }
}
