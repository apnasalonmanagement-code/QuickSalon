import 'package:flutter/material.dart';

enum SalonGenderTheme { boy, girl }

// Theme Notifier placed here so all screens/pages can import it and avoid errors
class ThemeNotifier extends ChangeNotifier {
  SalonGenderTheme _currentTheme = SalonGenderTheme.boy;

  SalonGenderTheme get currentTheme => _currentTheme;

  void setTheme(SalonGenderTheme theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }
}

class AppTheme {
  AppTheme._();

  // Dynamic Theme Generator based on selection (Boy = Blue theme, Girl = Pink theme)
  static ThemeData getTheme(SalonGenderTheme genderTheme) {
    final bool isBoy = genderTheme == SalonGenderTheme.boy;

    // Vibrant multi-color primary accents combined with requested theme colors
    final primaryColor = isBoy ? const Color(0xFF2196F3) : const Color(0xFFE91E63);
    final secondaryColor = isBoy ? const Color(0xFF00BCD4) : const Color(0xFFFF4081);
    final backgroundColor = isBoy ? const Color(0xFFF0F8FF) : const Color(0xFFFFF0F5); // Soft floral background tint

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.4),
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryColor.withOpacity(0.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: primaryColor),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  // Default fallback theme
  static ThemeData lightTheme = getTheme(SalonGenderTheme.boy);
}