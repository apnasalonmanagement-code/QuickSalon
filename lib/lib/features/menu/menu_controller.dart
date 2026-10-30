import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/service_model.dart';
import '../../repositories/service_repository.dart';

class SalonMenuController extends ChangeNotifier {
  SalonMenuController({
    ServiceRepository? repository,
  }) : _repository = repository ?? ServiceRepository();

  final ServiceRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceModel> _services = <ServiceModel>[];

  StreamSubscription<List<ServiceModel>>? _subscription;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<ServiceModel> get services =>
      List.unmodifiable(_services);

  Map<String, List<ServiceModel>> get groupedServices {
    final Map<String, List<ServiceModel>> result =
        <String, List<ServiceModel>>{};

    for (final service in _services) {
      final String category =
          service.categoryName.trim();

      if (category.isEmpty) {
        continue;
      }

      result
          .putIfAbsent(
            category,
            () => <ServiceModel>[],
          )
          .add(service);
    }

    return result;
  }

  List<String> get categories {
    final List<String> values =
        groupedServices.keys.toList();

    values.sort(
      (a, b) => a
          .toLowerCase()
          .compareTo(
            b.toLowerCase(),
          ),
    );

    return values;
  }

  // ============================================================
  // LOAD SERVICES
  // ============================================================

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result =
          await _repository.getActiveServices();

      _services = result;
    } catch (error) {
      _errorMessage =
          _cleanError(error);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<bool> addService({
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    bool request = false,
  }) async {
    _errorMessage = null;

    notifyListeners();

    try {
      await _repository.createService(
        categoryName: categoryName,
        serviceName: serviceName,
        durationMinutes: durationMinutes,
        price: price,
        request: request,
      );

      await load();

      return true;
    } catch (error) {
      _errorMessage =
          _cleanError(error);

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // RENAME CATEGORY
  // ============================================================

  Future<bool> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    _errorMessage = null;

    notifyListeners();

    try {
      await _repository.renameCategory(
        oldName: oldName,
        newName: newName,
      );

      await load();

      return true;
    } catch (error) {
      _errorMessage =
          _cleanError(error);

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void startRealtime() {
    _subscription?.cancel();

    _subscription =
        _repository.watchActiveServices().listen(
      (value) {
        _services = value;

        notifyListeners();
      },
      onError: (Object error) {
        // Do not remove already loaded services
        // if realtime temporarily fails.
      },
    );
  }

  void stopRealtime() {
    _subscription?.cancel();

    _subscription = null;
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final String message =
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim();

    if (message.isEmpty) {
      return 'Something went wrong.';
    }

    return message;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    stopRealtime();

    super.dispose();
  }
}