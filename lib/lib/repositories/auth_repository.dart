import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';
import '../models/profile_model.dart';

class AuthRepository {
  AuthRepository({
    AuthService? authService,
  }) : _authService =
            authService ?? AuthService();

  final AuthService _authService;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _authService.signIn(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception(
        'Login failed. User not found.',
      );
    }

    final profileMap =
        await _authService.getProfile(user.id);

    if (profileMap == null) {
      await _authService.signOut();

      throw Exception(
        'Management profile not found.',
      );
    }

    final profile =
        ProfileModel.fromMap(profileMap);

    // Only owner and manager can access
    // the management application.
    if (!profile.isManagementUser) {
      await _authService.signOut();

      throw Exception(
        'You are not authorized to access '
        'ApnaSalon Management.',
      );
    }

    // Management account must have a shop.
    if (!profile.hasShop) {
      await _authService.signOut();

      throw Exception(
        'No shop is assigned to this account.',
      );
    }

    return profile;
  }

  // ============================================================
  // OWNER REGISTRATION
  // ============================================================

  Future<ProfileModel> registerOwner({
    required String name,
    required String email,
    required String phone,
    required String city,
    required DateTime dob,
    required String password,
    required String shopName,
    required String shopPhone,
    required String shopCity,
    required String shopType,
    double? latitude,
    double? longitude,
    String? locationUrl,
    String? description,
    String? openingTime,
    String? closingTime,
  }) async {
    // ----------------------------------------------------------
    // 1. Create Auth account
    // ----------------------------------------------------------

    final authResponse =
        await _authService.signUp(
      email: email,
      password: password,
    );

    final user = authResponse.user;

    if (user == null) {
      throw Exception(
        'Unable to create authentication account.',
      );
    }

    // ----------------------------------------------------------
    // 2. Supabase may require email confirmation.
    // ----------------------------------------------------------

    if (authResponse.session == null) {
      throw Exception(
        'Account created successfully. '
        'Please verify your email before logging in.',
      );
    }

    String? shopId;

    try {
      // --------------------------------------------------------
      // 3. Create shop
      // --------------------------------------------------------

      final shopData = <String, dynamic>{
        'shop_name': shopName.trim(),
        'city': shopCity.trim(),
        'shop_type': shopType,
        'phone': shopPhone.trim().isEmpty
            ? null
            : shopPhone.trim(),
        'location_url':
            locationUrl?.trim().isEmpty == true
                ? null
                : locationUrl?.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'description':
            description?.trim().isEmpty == true
                ? null
                : description?.trim(),
        'opening_time': openingTime,
        'closing_time': closingTime,

        // Database defaults:
        // rating = 0
        // status = true
      };

      final shopResponse = await _authService.client
          .from('shops')
          .insert(shopData)
          .select()
          .single();

      shopId = shopResponse['id'] as String;

      // --------------------------------------------------------
      // 4. Create profile
      // --------------------------------------------------------

      final profileData = {
        'id': user.id,
        'name': name.trim(),
        'phone': phone.trim().isEmpty
            ? null
            : phone.trim(),
        'city': city.trim().isEmpty
            ? null
            : city.trim(),
        'dob':
            '${dob.year.toString().padLeft(4, '0')}-'
            '${dob.month.toString().padLeft(2, '0')}-'
            '${dob.day.toString().padLeft(2, '0')}',

        // IMPORTANT:
        // We explicitly set owner.
        'role': 'owner',

        'shop_id': shopId,

        // Database default:
        // profile_image_url = null
      };

      final profileResponse =
          await _authService.client
              .from('profiles')
              .insert(profileData)
              .select()
              .single();

      return ProfileModel.fromMap(
        profileResponse,
      );
    } catch (e) {
      // --------------------------------------------------------
      // If profile creation fails after shop creation,
      // remove the newly-created shop.
      // --------------------------------------------------------

      if (shopId != null) {
        try {
          await _authService.client
              .from('shops')
              .delete()
              .eq('id', shopId);
        } catch (_) {
          // Do not hide the original error.
        }
      }

      throw Exception(
        'Registration failed: $e',
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    await _authService.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  Future<void> updatePassword(String password) async {
    await _authService.auth.updateUser(UserAttributes(password: password));
    await _authService.signOut();
  }

  Future<void> deleteCurrentAccount() async {
    final response = await _authService.client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw Exception('Unable to delete account. Please try again or contact support.');
    }
    await _authService.signOut();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _authService.signOut();
  }

  bool get isAuthenticated {
    return _authService.isAuthenticated;
  }

  String? get currentUserId {
    return _authService.currentUser?.id;
  }
}