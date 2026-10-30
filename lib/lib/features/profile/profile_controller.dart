import 'package:flutter/foundation.dart';
import '../../repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({ProfileRepository? repository}) : _repository = repository ?? ProfileRepository();
  final ProfileRepository _repository;
  Map<String, dynamic>? profile;
  bool isLoading = false;
  bool isSaving = false;
  bool isChangingPassword = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try { profile = await _repository.getCurrentProfile(); }
    catch (e) { errorMessage = _clean(e); }
    finally { isLoading = false; notifyListeners(); }
  }

  Future<bool> save({required String name, required String phone, String? imageUrl}) async {
    if (name.trim().length < 2) { errorMessage = 'Name must contain at least 2 characters.'; notifyListeners(); return false; }
    isSaving = true; errorMessage = null; notifyListeners();
    try { profile = await _repository.updateProfile(name: name, phone: phone, imageUrl: imageUrl); return true; }
    catch (e) { errorMessage = _clean(e); return false; }
    finally { isSaving = false; notifyListeners(); }
  }

  Future<bool> changePassword(String password, String confirmation) async {
    if (password.length < 8) { errorMessage = 'Password must contain at least 8 characters.'; notifyListeners(); return false; }
    if (password != confirmation) { errorMessage = 'Passwords do not match.'; notifyListeners(); return false; }
    isChangingPassword = true; errorMessage = null; notifyListeners();
    try { await _repository.changePassword(password); return true; }
    catch (e) { errorMessage = _clean(e); return false; }
    finally { isChangingPassword = false; notifyListeners(); }
  }

  Future<void> logout() => _repository.logout();
  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
