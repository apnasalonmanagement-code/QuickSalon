import '../core/services/supabase_service.dart';
import '../models/shop_model.dart';

class ShopRepository {
  Future<List<ShopModel>> loadActiveShops() async {
    final response = await SupabaseService.client
        .from('shops')
        .select()
        .eq('status', true)
        .order('shop_name', ascending: true);

    return (response as List)
        .map((item) => ShopModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ShopModel>> loadNearbyShops({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    final response = await SupabaseService.client.rpc(
      'get_nearby_shops',
      params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_meters': radiusMeters,
      },
    );

    return (response as List)
        .map(
          (item) => ShopModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}