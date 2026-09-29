import 'package:flutter/foundation.dart';

import '../../models/shop_model.dart';
import '../../repositories/shop_repository.dart';

class ShopsController extends ChangeNotifier {
  ShopsController({ShopRepository? repository})
      : _repository = repository ?? ShopRepository();

  final ShopRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<ShopModel> _shops = [];
  String _searchQuery = '';
  String? _selectedCity;

  List<ShopModel> get shops {
    final query = _searchQuery.trim().toLowerCase();
    final city = _selectedCity?.trim().toLowerCase();

    return List.unmodifiable(_shops.where((shop) {
      final matchesSearch = query.isEmpty ||
          shop.shopName.toLowerCase().contains(query) ||
          shop.city.toLowerCase().contains(query);
      final matchesCity = city == null || city.isEmpty ||
          shop.city.trim().toLowerCase() == city;
      return matchesSearch && matchesCity;
    }));
  }

  List<String> get cities {
    final unique = <String>{};
    for (final shop in _shops) {
      final city = shop.city.trim();
      if (city.isNotEmpty) unique.add(city);
    }
    final result = unique.toList()..sort((a, b) => a.compareTo(b));
    return List.unmodifiable(result);
  }

  String? get selectedCity => _selectedCity;

  Future<void> loadActiveShops() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _shops = await _repository.loadActiveShops();
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

  void selectCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Unable to load salons. Please try again.'
        : message;
  }
}
