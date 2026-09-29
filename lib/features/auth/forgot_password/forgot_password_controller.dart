import 'package:flutter/material.dart';

import '../../../repositories/auth_repository.dart';

class ForgotPasswordController
    extends ChangeNotifier {
  final AuthRepository _repository =
      AuthRepository();

  bool _isLoading = false;

  String? _errorMessage;

  bool get isLoading =>
      _isLoading;

  String? get errorMessage =>
      _errorMessage;

  Future<bool> sendResetEmail(
    String email,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      await _repository
          .sendPasswordResetEmail(
        email,
      );

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