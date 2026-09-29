import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/shop_model.dart';
import '../../repositories/favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController({
    FavoritesRepository? repository,
    SupabaseClient? client,
  })  : _repository = repository ?? FavoritesRepository(),
        _client = client ?? Supabase.instance.client;

  final FavoritesRepository _repository;
  final SupabaseClient _client;

  List<ShopModel> _favorites = const [];
  Set<String> _favoriteShopIds = const <String>{};
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _customerId;
  RealtimeChannel? _channel;

  List<ShopModel> get favorites => List.unmodifiable(_favorites);
  Set<String> get favoriteShopIds => Set.unmodifiable(_favoriteShopIds);
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String shopId) => _favoriteShopIds.contains(shopId);

  Future<void> initialize() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _favorites = const [];
      _favoriteShopIds = const <String>{};
      _errorMessage = 'Please sign in to view your favorites.';
      notifyListeners();
      return;
    }
    _customerId = user.id;
    await loadFavorites();
    _subscribeRealtime();
  }

  Future<void> loadFavorites() async {
    final customerId = _customerId ?? _client.auth.currentUser?.id;
    if (customerId == null || customerId.isEmpty) {
      _favorites = const [];
      _favoriteShopIds = const <String>{};
      _errorMessage = 'Your session has expired. Please sign in again.';
      notifyListeners();
      return;
    }

    _customerId = customerId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _repository.loadCustomerFavorites(customerId),
        _repository.loadFavoriteShopIds(customerId),
      ]);
      _favorites = results[0] as List<ShopModel>;
      _favoriteShopIds = results[1] as Set<String>;
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String shopId) async {
    final customerId = _customerId ?? _client.auth.currentUser?.id;
    if (customerId == null || customerId.isEmpty) {
      _errorMessage = 'Your session has expired. Please sign in again.';
      notifyListeners();
      return false;
    }

    final wasFavorite = isFavorite(shopId);
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(customerId: customerId, shopId: shopId);
      } else {
        await _repository.addFavorite(customerId: customerId, shopId: shopId);
      }
      await loadFavorites();
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    final customerId = _customerId;
    if (customerId == null || customerId.isEmpty) return;

    _channel?.unsubscribe();
    _channel = _client.channel('customer_favorites_$customerId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (_) => unawaited(loadFavorites()),
        )
        .subscribe();
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
