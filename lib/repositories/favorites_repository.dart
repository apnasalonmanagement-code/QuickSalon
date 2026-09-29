import '../core/services/supabase_service.dart';
import '../models/shop_model.dart';

class FavoritesRepository {
  FavoritesRepository();

  Future<List<ShopModel>> loadCustomerFavorites(String customerId) async {
    if (customerId.trim().isEmpty) return const [];

    final rows = await SupabaseService.client
        .from('favorites')
        .select('shop_id, created_at')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    final favoriteRows = List<Map<String, dynamic>>.from(rows);
    final shopIds = favoriteRows
        .map((row) => row['shop_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (shopIds.isEmpty) return const [];

    final shopsResponse = await SupabaseService.client
        .from('shops')
        .select()
        .inFilter('id', shopIds);

    final shopsById = <String, ShopModel>{};
    for (final raw in List<Map<String, dynamic>>.from(shopsResponse)) {
      final shop = ShopModel.fromMap(raw);
      shopsById[shop.id] = shop;
    }

    final result = <ShopModel>[];
    for (final shopId in shopIds) {
      final shop = shopsById[shopId];
      if (shop != null) result.add(shop);
    }
    return result;
  }

  Future<Set<String>> loadFavoriteShopIds(String customerId) async {
    if (customerId.trim().isEmpty) return const <String>{};

    final rows = await SupabaseService.client
        .from('favorites')
        .select('shop_id')
        .eq('customer_id', customerId);

    return List<Map<String, dynamic>>.from(rows)
        .map((row) => row['shop_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> addFavorite({
    required String customerId,
    required String shopId,
  }) async {
    if (customerId.trim().isEmpty || shopId.trim().isEmpty) {
      throw Exception('Invalid favorite request.');
    }

    await SupabaseService.client.from('favorites').upsert(
      {
        'customer_id': customerId,
        'shop_id': shopId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'customer_id,shop_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeFavorite({
    required String customerId,
    required String shopId,
  }) async {
    await SupabaseService.client
        .from('favorites')
        .delete()
        .eq('customer_id', customerId)
        .eq('shop_id', shopId);
  }
}
