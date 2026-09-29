import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import '../../repositories/auth_repository.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get _client =>
      SupabaseService.client;

  static final AuthRepository _repository =
      AuthRepository();

  static User? get currentUser =>
      _client.auth.currentUser;

  static Session? get currentSession =>
      _client.auth.currentSession;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword({
    required String email,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email,
    );
  }

  static Future<UserResponse> updatePassword({
    required String password,
  }) async {
    return _client.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  static Future<ProfileModel?>
      getCurrentProfile() async {
    final user =
        _repository.currentUser;

    if (user == null) {
      return null;
    }

    return await _repository
        .getProfile(user.id);
  }

  static Future<bool>
      isCurrentUserCustomer() async {
    final user =
        _repository.currentUser;

    if (user == null) {
      return false;
    }

    return await _repository
        .isCustomer(user.id);
  }
}