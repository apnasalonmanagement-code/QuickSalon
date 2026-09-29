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
}
