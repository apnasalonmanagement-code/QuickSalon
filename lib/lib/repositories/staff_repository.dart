import '../core/services/auth_service.dart';

class StaffRepository {
  StaffRepository({AuthService? authService}) : _auth = authService ?? AuthService();

  final AuthService _auth;

  Future<String> _shopId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Your session has expired. Please log in again.');
    }

    final profile = await _auth.getProfile(user.id);
    if (profile == null) throw Exception('Management profile not found.');

    final role = profile['role']?.toString();
    if (role != 'owner' && role != 'manager') {
      throw Exception('You are not authorized to manage staff.');
    }

    final shopId = profile['shop_id']?.toString();
    if (shopId == null || shopId.isEmpty || shopId == 'null') {
      throw Exception('No shop is assigned to this account.');
    }
    return shopId;
  }

  Future<List<Map<String, dynamic>>> getStaff() async {
    final shopId = await _shopId();
    final rows = await _auth.client
        .from('staff')
        .select()
        .eq('shop_id', shopId)
        .order('name');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createStaff({
    required String name,
    String? phone,
    required String role,
    String? imageUrl,
    bool status = true,
  }) async {
    final shopId = await _shopId();
    final row = await _auth.client
        .from('staff')
        .insert({
          'shop_id': shopId,
          'name': name.trim(),
          'phone': _nullable(phone),
          'role': role.trim(),
          'image_url': _nullable(imageUrl),
          'status': status,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateStaff({
    required String staffId,
    required String name,
    String? phone,
    required String role,
    String? imageUrl,
    required bool status,
  }) async {
    final shopId = await _shopId();
    final row = await _auth.client
        .from('staff')
        .update({
          'name': name.trim(),
          'phone': _nullable(phone),
          'role': role.trim(),
          'image_url': _nullable(imageUrl),
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', staffId)
        .eq('shop_id', shopId)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> setStatus({
    required String staffId,
    required bool status,
  }) async {
    final shopId = await _shopId();
    final row = await _auth.client
        .from('staff')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', staffId)
        .eq('shop_id', shopId)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  /// Deletes a staff record only when no historical/current appointment
  /// references it. Otherwise the caller should deactivate the staff member.
  Future<void> deleteStaff(String staffId) async {
    final shopId = await _shopId();

    final appointmentRows = await _auth.client
        .from('appointments')
        .select('id')
        .eq('shop_id', shopId)
        .eq('staff_id', staffId)
        .limit(1);

    if ((appointmentRows as List).isNotEmpty) {
      throw Exception(
        'This staff member has appointments. Deactivate the staff member instead of deleting them.',
      );
    }

    await _auth.client
        .from('staff')
        .delete()
        .eq('id', staffId)
        .eq('shop_id', shopId);
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
