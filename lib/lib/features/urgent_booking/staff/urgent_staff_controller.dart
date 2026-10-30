import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UrgentStaffController extends ChangeNotifier {
  UrgentStaffController({required this.shopId}) {
    loadStaff();
  }

  final String shopId;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedStaffId;

  List<Map<String, dynamic>> get staff => List.unmodifiable(_staff);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedStaffId => _selectedStaffId;

  Map<String, dynamic>? get selectedStaff {
    for (final member in _staff) {
      if (member['id']?.toString() == _selectedStaffId) return member;
    }
    return null;
  }

  Future<void> loadStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('staff')
          .select('id, shop_id, name, phone, role, image_url, status')
          .eq('shop_id', shopId)
          .eq('status', true)
          .order('name', ascending: true);

      _staff = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _staff = [];
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStaff(String staffId) {
    _selectedStaffId = staffId;
    notifyListeners();
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
}
