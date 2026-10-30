import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UrgentServicesController extends ChangeNotifier {
  UrgentServicesController({required this.shopId}) {
    loadServices();
  }

  final String shopId;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _services = [];
  final Set<String> _selectedIds = <String>{};
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get services => List.unmodifiable(_services);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<String> get categories => _services
      .map((service) => service['category_name']?.toString() ?? 'Other')
      .toSet()
      .toList();

  List<Map<String, dynamic>> servicesForCategory(String category) => _services
      .where((service) => (service['category_name']?.toString() ?? 'Other') == category)
      .toList();

  int get totalDuration => _services
      .where((service) => _selectedIds.contains(service['id']?.toString()))
      .fold<int>(0, (sum, service) => sum + _asInt(service['duration_minutes']));

  double get totalPrice => _services
      .where((service) => _selectedIds.contains(service['id']?.toString()))
      .fold<double>(0, (sum, service) => sum + _asDouble(service['price']));

  List<Map<String, dynamic>> get selectedServices => _services
      .where((service) => _selectedIds.contains(service['id']?.toString()))
      .toList();

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('services')
          .select('id, shop_id, category_name, service_name, duration_minutes, price, request, image_url')
          .eq('shop_id', shopId)
          .eq('status', true)
          .order('category_name', ascending: true)
          .order('service_name', ascending: true);

      _services = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _services = [];
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleService(String serviceId) {
    if (_selectedIds.contains(serviceId)) {
      _selectedIds.remove(serviceId);
    } else {
      _selectedIds.add(serviceId);
    }
    notifyListeners();
  }

  bool isSelected(String serviceId) => _selectedIds.contains(serviceId);

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
