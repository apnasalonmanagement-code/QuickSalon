import 'package:flutter/foundation.dart';

import '../../../repositories/service_repository.dart';

class CategoryController extends ChangeNotifier {
  CategoryController({ServiceRepository? repository})
      : _repository = repository ?? ServiceRepository();

  final ServiceRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> createCategoryWithFirstService({
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    required bool request,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.createService(
        categoryName: categoryName,
        serviceName: serviceName,
        durationMinutes: durationMinutes,
        price: price,
        request: request,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
