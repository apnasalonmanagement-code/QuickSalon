import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../models/user_address_model.dart';

class UserAddressRepository {
  UserAddressRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    return id;
  }

  Future<List<UserAddressModel>> loadAddresses() async {
    final rows = await _client
        .from('user_addresses')
        .select('id, user_id, label, full_address, landmark, latitude, longitude, is_default, created_at')
        .eq('user_id', _userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => UserAddressModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  Future<UserAddressModel> saveAddress({
    String? id,
    required String label,
    required String fullAddress,
    String? landmark,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    final userId = _userId;

    if (fullAddress.trim().isEmpty) {
      throw Exception('Please choose a location with a readable address.');
    }
    if (latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      throw Exception('The selected map coordinates are invalid.');
    }

    if (isDefault) {
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    final data = <String, dynamic>{
      'user_id': userId,
      'label': label.trim().isEmpty ? 'Other' : label.trim(),
      'full_address': fullAddress.trim(),
      'landmark': landmark?.trim().isEmpty == true ? null : landmark?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final dynamic row;
    if (id == null) {
      row = await _client
          .from('user_addresses')
          .insert(data)
          .select('id, user_id, label, full_address, landmark, latitude, longitude, is_default, created_at')
          .single();
    } else {
      row = await _client
          .from('user_addresses')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select('id, user_id, label, full_address, landmark, latitude, longitude, is_default, created_at')
          .single();
    }

    return UserAddressModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteAddress(String id) async {
    await _client
        .from('user_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> setDefaultAddress(String id) async {
    final userId = _userId;
    await _client
        .from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
    await _client
        .from('user_addresses')
        .update({
          'is_default': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId);
  }
}
