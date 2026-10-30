import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  AuthService({SupabaseService? supabaseService})
      : _supabaseService =
            supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  SupabaseClient get client => _supabaseService.client;

  GoTrueClient get auth => _supabaseService.auth;

  Session? get currentSession => auth.currentSession;

  User? get currentUser => auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await auth.resetPasswordForEmail(
      email.trim(),
    );
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile(
    String userId,
  ) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }
}