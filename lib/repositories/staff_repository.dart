import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/staff_model.dart';

class StaffRepository {
  StaffRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<StaffModel>> loadActiveStaffForShop(String shopId) async {
    final data = await _client
        .from('staff')
        .select()
        .eq('shop_id', shopId)
        .eq('status', true)
        .order('name', ascending: true);

    return (data as List)
        .map((item) => StaffModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
