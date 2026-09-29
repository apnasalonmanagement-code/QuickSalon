import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/profile_model.dart';

class CustomerProfileRepository {
  CustomerProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<ProfileModel> loadCurrentCustomerProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    final response = await _client
        .from('profiles')
        .select('id, name, phone, city, dob, role, shop_id, profile_image_url, created_at, updated_at')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Customer profile not found.');
    }

    final profile = ProfileModel.fromMap(Map<String, dynamic>.from(response));
    if (profile.role.toLowerCase() != 'customer') {
      throw Exception('This account is not a customer account.');
    }
    return profile;
  }

  Future<ProfileModel> updateCurrentCustomerProfile({
    required String name,
    required String phone,
    required String city,
    DateTime? dob,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    final existing = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null || existing['role']?.toString().toLowerCase() != 'customer') {
      throw Exception('You are not authorized to edit this profile.');
    }

    final row = await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'city': city.trim().isEmpty ? null : city.trim(),
          'dob': dob == null ? null : _dateString(dob),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id)
        .select('id, name, phone, city, dob, role, shop_id, profile_image_url, created_at, updated_at')
        .single();

    return ProfileModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> changePassword(String password) async {
    if (currentUser == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw Exception('Email is required.');
    }
    await _client.auth.resetPasswordForEmail(normalized);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  String _dateString(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
