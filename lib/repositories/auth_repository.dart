import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/profile_model.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Unable to create account.');
    }

    // Uses the existing public.profiles structure exactly as provided.
    // No shop, management, appointment, availability, or slot data is created.
    await _client.from('profiles').upsert(
      {
        'id': user.id,
        'name': name.trim(),
        'phone': phone.trim(),
        'role': 'customer',
        'shop_id': null,
      },
      onConflict: 'id',
    );

    return response;
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProfileModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<bool> isCustomer(String userId) async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return false;
    }

    return response['role'] == 'customer';
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
