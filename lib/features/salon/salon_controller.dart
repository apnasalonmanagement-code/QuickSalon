import 'package:flutter/foundation.dart';
import '../../repositories/shop_repository.dart';

class SalonController extends ChangeNotifier {
  SalonController({ShopRepository? repository}) : _repository = repository ?? ShopRepository();
  final ShopRepository _repository;
  Map<String, dynamic>? shop;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try { shop = await _repository.getCurrentShop(); }
    catch (e) { errorMessage = _clean(e); }
    finally { isLoading = false; notifyListeners(); }
  }

  Future<bool> save(Map<String, dynamic> values) async {
    isSaving = true; errorMessage = null; notifyListeners();
    try { shop = await _repository.updateCurrentShop(values); return true; }
    catch (e) { errorMessage = _clean(e); return false; }
    finally { isSaving = false; notifyListeners(); }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
