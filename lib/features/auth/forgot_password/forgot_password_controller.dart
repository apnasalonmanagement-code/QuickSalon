import 'package:flutter/foundation.dart';

import '../../../repositories/auth_repository.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({AuthRepository? authRepository})
      : _repository = authRepository ?? AuthRepository();

  final AuthRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _otpVerified = false;
  String? _email;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get otpVerified => _otpVerified;
  String? get email => _email;

  Future<bool> sendResetEmail(String email) async {
    _start();
    try {
      _email = email.trim();
      await _repository.sendPasswordResetEmail(_email!);
      _successMessage = 'If this email is registered, a recovery code has been sent. Check your inbox and spam folder.';
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      return false;
    } finally { _finish(); }
  }

  Future<bool> verifyOtp(String token) async {
    if (_email == null) { _errorMessage = 'Enter your email and request a code first.'; notifyListeners(); return false; }
    _start();
    try {
      await _repository.verifyPasswordResetOtp(email: _email!, token: token);
      _otpVerified = true;
      _successMessage = 'Email code verified. Choose a new password.';
      return true;
    } catch (e) {
      _errorMessage = 'Code verification failed. Check the code or request a new one.';
      return false;
    } finally { _finish(); }
  }

  Future<bool> setNewPassword(String password) async {
    if (!_otpVerified) { _errorMessage = 'Verify the email code first.'; notifyListeners(); return false; }
    _start();
    try {
      await _repository.updatePassword(password);
      _successMessage = 'Password updated successfully. You can now log in.';
      return true;
    } catch (e) { _errorMessage = _clean(e); return false; }
    finally { _finish(); }
  }

  void _start() { _isLoading = true; _errorMessage = null; _successMessage = null; notifyListeners(); }
  void _finish() { _isLoading = false; notifyListeners(); }
  String _clean(Object error) => error.toString().replaceFirst('Exception: ', '');
}
