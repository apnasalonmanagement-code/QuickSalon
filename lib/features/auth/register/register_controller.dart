import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/auth_repository.dart';

class RegistrationResult {
  final bool success;
  final bool hasActiveSession;
  final String? message;

  const RegistrationResult({
    required this.success,
    required this.hasActiveSession,
    this.message,
  });
}

class RegisterController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<RegistrationResult> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      final hasActiveSession = response.session != null;

      return RegistrationResult(
        success: true,
        hasActiveSession: hasActiveSession,
        message: hasActiveSession
            ? 'Account created successfully.'
            : 'Account created. Please verify your email, then login.',
      );
    } on AuthException catch (e) {
      _errorMessage = e.message;

      return RegistrationResult(
        success: false,
        hasActiveSession: false,
        message: e.message,
      );
    } on PostgrestException catch (e) {
      _errorMessage = e.message;

      return RegistrationResult(
        success: false,
        hasActiveSession: false,
        message: e.message,
      );
    } catch (e) {
      _errorMessage = e.toString();

      return RegistrationResult(
        success: false,
        hasActiveSession: false,
        message: _errorMessage,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
