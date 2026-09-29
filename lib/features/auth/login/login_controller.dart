import 'package:flutter/material.dart';

import '../../../repositories/auth_repository.dart';

class LoginController
    extends ChangeNotifier {
  final AuthRepository _repository =
      AuthRepository();

  bool _isLoading = false;

  String? _errorMessage;

  bool get isLoading =>
      _isLoading;

  String? get errorMessage =>
      _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      final response =
          await _repository.login(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        _errorMessage =
            'Login failed.';

        return false;
      }

      final isCustomer =
          await _repository.isCustomer(
        user.id,
      );

      if (!isCustomer) {
        await _repository.logout();

        _errorMessage =
            'This account is not registered as a customer.';

        return false;
      }

      return true;
    } catch (e) {
      _errorMessage =
          e.toString();

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}