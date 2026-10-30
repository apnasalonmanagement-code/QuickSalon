import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../models/profile_model.dart';
import '../management/management_shell.dart';
import 'login/login_screen.dart';

/// Restores a persisted Supabase session and sends valid management users
/// directly into the app. Users remain logged in until they explicitly log out.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final user = _auth.currentUser;
      if (user != null && _auth.currentSession != null) {
        final profileMap = await _auth.getProfile(user.id);
        if (profileMap != null) {
          final profile = ProfileModel.fromMap(profileMap);
          _authorized = profile.isManagementUser && profile.hasShop;
        }
        if (!_authorized) {
          await _auth.signOut();
        }
      }
    } catch (_) {
      _authorized = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authorized) {
      return const ManagementShell(initialIndex: 1);
    }
    return const LoginScreen();
  }
}
