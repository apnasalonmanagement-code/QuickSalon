import '../core/services/supabase_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  Future<List<ServiceModel>> loadActiveServicesForShop(String shopId) async {
    final response = await SupabaseService.client
        .from('services')
        .select()
        .eq('shop_id', shopId)
        .eq('status', true)
        .order('category_name', ascending: true)
        .order('service_name', ascending: true);

    return (response as List)
        .map((item) => ServiceModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }
}
