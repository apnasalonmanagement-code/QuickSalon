import '../core/services/auth_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  ServiceRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<String> _getManagementShopId() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    final profile = await _authService.getProfile(user.id);
    if (profile == null) {
      throw Exception('Management profile not found.');
    }

    final role = profile['role']?.toString();
    final shopId = profile['shop_id']?.toString();

    if (role != 'owner' && role != 'manager') {
      throw Exception('You are not authorized to manage services.');
    }

    if (shopId == null || shopId.isEmpty || shopId == 'null') {
      throw Exception('No shop is assigned to this account.');
    }

    return shopId;
  }

  Future<String> getManagementShopId() => _getManagementShopId();

  Future<List<String>> getCategories() async {
    final shopId = await _getManagementShopId();

    final rows = await _authService.client
        .from('services')
        .select('category_name')
        .eq('shop_id', shopId)
        .order('category_name');

    final categories = <String>{};
    for (final row in rows as List) {
      final value = row['category_name']?.toString().trim() ?? '';
      if (value.isNotEmpty) categories.add(value);
    }

    final result = categories.toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<List<ServiceModel>> getActiveServices() async {
    final shopId = await _getManagementShopId();

    final rows = await _authService.client
        .from('services')
        .select()
        .eq('shop_id', shopId)
        .eq('status', true)
        .order('category_name')
        .order('service_name');

    return (rows as List)
        .map(
          (row) => ServiceModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ServiceModel> getService(String serviceId) async {
    final shopId = await _getManagementShopId();

    final row = await _authService.client
        .from('services')
        .select()
        .eq('id', serviceId)
        .eq('shop_id', shopId)
        .maybeSingle();

    if (row == null) {
      throw Exception('Service not found or access denied.');
    }

    return ServiceModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<ServiceModel> createService({
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    required bool request,
    String? imageUrl,
  }) async {
    final shopId = await _getManagementShopId();
    _validate(
      categoryName: categoryName,
      serviceName: serviceName,
      durationMinutes: durationMinutes,
      price: price,
    );

    final row = await _authService.client
        .from('services')
        .insert({
          'shop_id': shopId,
          'category_name': categoryName.trim(),
          'service_name': serviceName.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'request': request,
          'status': true,
          if (imageUrl != null && imageUrl.trim().isNotEmpty)
            'image_url': imageUrl.trim(),
        })
        .select()
        .single();

    return ServiceModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<ServiceModel> updateService({
    required String serviceId,
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
    required bool request,
    required bool status,
    String? imageUrl,
    bool replaceImageUrl = false,
  }) async {
    final shopId = await _getManagementShopId();
    _validate(
      categoryName: categoryName,
      serviceName: serviceName,
      durationMinutes: durationMinutes,
      price: price,
    );

    final data = <String, dynamic>{
      'category_name': categoryName.trim(),
      'service_name': serviceName.trim(),
      'duration_minutes': durationMinutes,
      'price': price,
      'request': request,
      'status': status,
    };

    if (replaceImageUrl) {
      data['image_url'] = imageUrl?.trim().isEmpty == true
          ? null
          : imageUrl?.trim();
    }

    final row = await _authService.client
        .from('services')
        .update(data)
        .eq('id', serviceId)
        .eq('shop_id', shopId)
        .select()
        .maybeSingle();

    if (row == null) {
      throw Exception('Service not found or update was not permitted.');
    }

    return ServiceModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  /// Deactivation is preferred over deleting the row. Existing appointments
  /// keep their historical snapshots and are never modified here.
  Future<void> deactivateService(String serviceId) async {
    final shopId = await _getManagementShopId();

    final rows = await _authService.client
        .from('services')
        .update({'status': false})
        .eq('id', serviceId)
        .eq('shop_id', shopId)
        .select('id');

    if ((rows as List).isEmpty) {
      throw Exception('Service not found or update was not permitted.');
    }
  }

  Future<void> activateService(String serviceId) async {
    final shopId = await _getManagementShopId();

    final rows = await _authService.client
        .from('services')
        .update({'status': true})
        .eq('id', serviceId)
        .eq('shop_id', shopId)
        .select('id');

    if ((rows as List).isEmpty) {
      throw Exception('Service not found or update was not permitted.');
    }
  }

  Future<void> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    final shopId = await _getManagementShopId();
    final oldCategory = oldName.trim();
    final newCategory = newName.trim();

    if (newCategory.isEmpty) {
      throw Exception('Category name is required.');
    }
    if (oldCategory == newCategory) return;

    await _authService.client
        .from('services')
        .update({'category_name': newCategory})
        .eq('shop_id', shopId)
        .eq('category_name', oldCategory);
  }

  Stream<List<ServiceModel>> watchActiveServices() {
    return _authService.client
        .from('services')
        .stream(primaryKey: ['id'])
        .order('category_name')
        .order('service_name')
        .asyncMap((_) => getActiveServices());
  }

  void _validate({
    required String categoryName,
    required String serviceName,
    required int durationMinutes,
    required double price,
  }) {
    if (categoryName.trim().isEmpty) {
      throw Exception('Category name is required.');
    }
    if (serviceName.trim().isEmpty) {
      throw Exception('Service name is required.');
    }
    if (durationMinutes <= 0) {
      throw Exception('Duration must be greater than 0 minutes.');
    }
    if (durationMinutes % 15 != 0) {
      throw Exception('Duration must be a multiple of 15 minutes.');
    }
    if (price < 0) {
      throw Exception('Price cannot be negative.');
    }
  }
}
