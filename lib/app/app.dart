import 'package:flutter/material.dart';

import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/user_shell/user_shell.dart';

import 'routes.dart';
import 'theme.dart';

class ApnaSalonApp extends StatelessWidget {
  const ApnaSalonApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder listens to the global theme toggle
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isSalonTheme,
      builder: (context, isSalon, child) {
        return MaterialApp(
          title: 'ApnaSalon',
          debugShowCheckedModeBanner: false,
          
          // Apply Salon (Blue) or Parlor (Pink) theme dynamically based on toggle
          theme: isSalon ? AppTheme.salonTheme : AppTheme.parlorTheme,
          
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
            AppRoutes.home: (_) => const UserShell(),
          },
        );
      },
    );
  }
}