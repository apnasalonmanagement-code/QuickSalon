import 'package:flutter/foundation.dart';

import '../../../models/profile_model.dart';
import '../../../core/constants/shop_constants.dart';
import '../../../repositories/auth_repository.dart';

class RegisterController extends ChangeNotifier {
  RegisterController({
    AuthRepository? authRepository,
  }) : _authRepository =
            authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  ProfileModel? _profile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  ProfileModel? get profile => _profile;

  Future<bool> registerOwner({
    required String name,
    required String email,
    required String phone,
    required String city,
    required DateTime dob,
    required String password,
    required String shopName,
    required String shopPhone,
    required String shopCity,
    required String shopType,
    String? locationUrl,
    double? latitude,
    double? longitude,
    String? description,
    String? openingTime,
    String? closingTime,
  }) async {
    final canonicalOwnerCity =
        ShopConstants.canonicalCity(city);

    final canonicalCity =
        ShopConstants.canonicalCity(shopCity);

    if (canonicalOwnerCity == null) {
      _errorMessage =
          'Please select a valid city.';
      notifyListeners();
      return false;
    }

    if (canonicalCity == null) {
      _errorMessage =
          'Please select a valid shop city.';
      notifyListeners();
      return false;
    }

    if (!ShopConstants.isValidShopType(shopType)) {
      _errorMessage =
          'Please select a valid shop type.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _profile =
          await _authRepository.registerOwner(
        name: name,
        email: email,
        phone: phone,
        city: canonicalOwnerCity,
        dob: dob,
        password: password,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: canonicalCity,
        shopType: shopType,
        locationUrl: locationUrl,
        latitude: latitude,
        longitude: longitude,
        description: description,
        openingTime: openingTime,
        closingTime: closingTime,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    final message =
        error.toString();

    if (message.contains(
      'User already registered',
    )) {
      return 'An account with this email already exists.';
    }

    if (message.contains(
      'duplicate key',
    )) {
      return 'This phone number or email is already registered.';
    }

    if (message.contains(
      'Password should be',
    )) {
      return 'Password does not meet the required security rules.';
    }

    if (message.contains(
      'Account created successfully',
    )) {
      return message
          .replaceFirst('Exception: ', '');
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
