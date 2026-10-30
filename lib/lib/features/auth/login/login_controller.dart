import 'package:flutter/foundation.dart';

import '../../../models/profile_model.dart';
import '../../../repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  LoginController({
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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _profile = await _authRepository.login(
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      _profile = null;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }

    if (message.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    }

    if (message.contains('not authorized')) {
      return 'You are not authorized to access the management app.';
    }

    if (message.contains('profile not found')) {
      return 'Management profile not found.';
    }

    if (message.contains('No shop')) {
      return 'No shop is assigned to this account.';
    }

    return 'Unable to login. Please try again.';
  }
}