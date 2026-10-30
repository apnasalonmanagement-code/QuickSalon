import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../models/service_model.dart';
import '../../../repositories/service_repository.dart';

class ServiceController extends ChangeNotifier {
  ServiceController({
    ServiceRepository? repository,
    CloudinaryService? cloudinaryService,
  })  : _repository = repository ?? ServiceRepository(),
        _cloudinaryService =
            cloudinaryService ?? const CloudinaryService();

  final ServiceRepository _repository;
  final CloudinaryService _cloudinaryService;

  bool isLoading = false;
  bool isUploadingImage = false;
  String? errorMessage;
  List<String> categories = const [];

  Future<void> loadCategories() async {
    try {
      categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      errorMessage = _cleanError(e);
      notifyListeners();
    }
  }

  Future<String?> uploadImage(XFile file) async {
    if (!_cloudinaryService.isConfigured) {
      return null;
    }

    isUploadingImage = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _cloudinaryService.uploadServiceImage(file);
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  Future<ServiceModel?> create({
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    required bool request,
    String? imageUrl,
  }) async {
    return _run(() async {
      return _repository.createService(
        categoryName: categoryName,
        serviceName: serviceName,
        durationMinutes: durationMinutes,
        price: price,
        request: request,
        imageUrl: imageUrl,
      );
    });
  }

  Future<ServiceModel?> update({
    required String serviceId,
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    required bool request,
    required bool status,
    String? imageUrl,
    bool replaceImageUrl = false,
  }) async {
    return _run(() async {
      return _repository.updateService(
        serviceId: serviceId,
        categoryName: categoryName,
        serviceName: serviceName,
        durationMinutes: durationMinutes,
        price: price,
        request: request,
        status: status,
        imageUrl: imageUrl,
        replaceImageUrl: replaceImageUrl,
      );
    });
  }

  Future<bool> deactivate(String serviceId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deactivateService(serviceId);
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activate(String serviceId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.activateService(serviceId);
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ServiceModel?> _run(
    Future<ServiceModel> Function() operation,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await operation();
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
    return message.isEmpty ? 'Something went wrong.' : message;
  }
}
