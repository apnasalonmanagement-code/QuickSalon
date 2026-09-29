import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../models/profile_model.dart';
import '../../repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    CustomerProfileRepository? repository,
    SupabaseClient? client,
  })  : _repository = repository ?? CustomerProfileRepository(client: client),
        _client = client ?? SupabaseService.client;

  final CustomerProfileRepository _repository;
  final SupabaseClient _client;

  ProfileModel? _profile;
  String? _email;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  bool _isSendingReset = false;
  bool _sessionExpired = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  ProfileModel? get profile => _profile;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isChangingPassword => _isChangingPassword;
  bool get isSendingReset => _isSendingReset;
  bool get sessionExpired => _sessionExpired;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _authSubscription ??= _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut && _client.auth.currentUser == null) {
        _sessionExpired = true;
        _profile = null;
        _email = null;
        notifyListeners();
      }
    });
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _sessionExpired = true;
        _profile = null;
        _email = null;
        return;
      }
      _sessionExpired = false;
      _email = user.email;
      _profile = await _repository.loadCurrentCustomerProfile();
    } catch (error) {
      _errorMessage = _clean(error);
      if (_client.auth.currentUser == null) _sessionExpired = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String name,
    required String phone,
    required String city,
    DateTime? dob,
  }) async {
    if (name.trim().length < 2) {
      _errorMessage = 'Name must contain at least 2 characters.';
      notifyListeners();
      return false;
    }
    if (phone.trim().isNotEmpty && phone.trim().length < 6) {
      _errorMessage = 'Enter a valid phone number.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.updateCurrentCustomerProfile(
        name: name,
        phone: phone,
        city: city,
        dob: dob,
      );
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      if (_client.auth.currentUser == null) _sessionExpired = true;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String password, String confirmation) async {
    if (password.length < 8) {
      _errorMessage = 'Password must contain at least 8 characters.';
      notifyListeners();
      return false;
    }
    if (password != confirmation) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.changePassword(password);
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      if (_client.auth.currentUser == null) _sessionExpired = true;
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail() async {
    final currentEmail = _client.auth.currentUser?.email?.trim() ?? '';
    if (currentEmail.isEmpty) {
      _errorMessage = 'No email address is available for this account.';
      notifyListeners();
      return false;
    }

    _isSendingReset = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendPasswordResetEmail(currentEmail);
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      return false;
    } finally {
      _isSendingReset = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _profile = null;
    _email = null;
    _sessionExpired = true;
    notifyListeners();
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
