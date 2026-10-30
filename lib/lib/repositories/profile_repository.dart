import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';

class ProfileRepository {
  ProfileRepository({AuthService? authService}) : _auth = authService ?? AuthService();
  final AuthService _auth;

  Future<Map<String, dynamic>> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Your session has expired. Please log in again.');
    final row = await _auth.getProfile(user.id);
    if (row == null) throw Exception('Management profile not found.');
    final result = Map<String, dynamic>.from(row);
    final shopId = result['shop_id']?.toString();
    if (shopId != null && shopId.isNotEmpty && shopId != 'null') {
      final shop = await _auth.client.from('shops').select('shop_name').eq('id', shopId).maybeSingle();
      if (shop != null) result['shop_name'] = shop['shop_name'];
    }
    return result;
  }

  Future<Map<String, dynamic>> updateProfile({required String name, required String phone, String? imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Your session has expired. Please log in again.');
    final row = await _auth.client.from('profiles').update({
      'name': name.trim(),
      'phone': phone.trim().isEmpty ? null : phone.trim(),
      'profile_image_url': imageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> changePassword(String password) async {
    if (_auth.currentUser == null) throw Exception('Your session has expired. Please log in again.');
    await _auth.client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> logout() => _auth.client.auth.signOut();
}
