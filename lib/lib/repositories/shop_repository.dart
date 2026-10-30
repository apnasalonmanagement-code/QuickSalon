import '../core/services/auth_service.dart';

class ShopRepository {
  ShopRepository({AuthService? authService}) : _auth = authService ?? AuthService();
  final AuthService _auth;

  Future<String> _shopId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Your session has expired. Please log in again.');
    final profile = await _auth.getProfile(user.id);
    if (profile == null) throw Exception('Management profile not found.');
    final role = profile['role']?.toString();
    final id = profile['shop_id']?.toString();
    if (role != 'owner' && role != 'manager') throw Exception('You are not authorized to manage this shop.');
    if (id == null || id.isEmpty || id == 'null') throw Exception('No shop is assigned to this account.');
    return id;
  }

  Future<Map<String, dynamic>> getCurrentShop() async {
    final id = await _shopId();
    final row = await _auth.client.from('shops').select().eq('id', id).maybeSingle();
    if (row == null) throw Exception('Shop not found or access denied.');
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateCurrentShop(Map<String, dynamic> values) async {
    final id = await _shopId();
    final row = await _auth.client.from('shops').update(values).eq('id', id).select().single();
    return Map<String, dynamic>.from(row);
  }
}
