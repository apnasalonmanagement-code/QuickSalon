import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Global Notifier: Set to true for Salon (Blue theme), false for Parlor (Pink theme)
  static final ValueNotifier<bool> isSalonTheme = ValueNotifier<bool>(false);

  // ==========================================
  // SALON THEME (Blue / Cyan / Multi-color GUI)
  // ==========================================
  static ThemeData get salonTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Bright Blue
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF00BCD4), // Cyan touches
        tertiary: const Color(0xFF03A9F4),
        background: const Color(0xFFF0F8FF), // Alice Blue Background
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F8FF),
      
      // Interactive Effects
      hoverColor: Colors.blue.withOpacity(0.1),
      splashColor: Colors.blueAccent.withOpacity(0.3),
      highlightColor: Colors.lightBlue.withOpacity(0.2),
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 6, // Adding shadow for 3D feel
        shadowColor: Colors.blueAccent,
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      
      inputDecorationTheme: _inputTheme(const Color(0xFF1976D2), const Color(0xFFE3F2FD)),
      filledButtonTheme: _buttonTheme(const Color(0xFF1976D2), const Color(0xFF00BCD4)),
    );
  }

  // ==========================================
  // PARLOR THEME (Pink / Purple / Floral GUI) - Default
  // ==========================================
  static ThemeData get parlorTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE91E63), // Pink
        primary: const Color(0xFFD81B60),
        secondary: const Color(0xFF9C27B0), // Purple touches
        tertiary: const Color(0xFFFF4081),
        background: const Color(0xFFFFF0F5), // Lavender Blush Background
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      
      // Interactive Effects
      hoverColor: Colors.pink.withOpacity(0.1),
      splashColor: Colors.pinkAccent.withOpacity(0.3),
      highlightColor: Colors.pink.withOpacity(0.2),
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 6, // Adding shadow for 3D feel
        shadowColor: Colors.pinkAccent,
        backgroundColor: Color(0xFFD81B60),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      
      inputDecorationTheme: _inputTheme(const Color(0xFFD81B60), const Color(0xFFFCE4EC)),
      filledButtonTheme: _buttonTheme(const Color(0xFFD81B60), const Color(0xFF9C27B0)),
    );
  }

  // ==========================================
  // AUTH THEME (Static / Neutral for Login & Register)
  // ==========================================
  static ThemeData get authTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        primary: const Color(0xFF212121),
        secondary: const Color(0xFF616161),
        background: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      
      inputDecorationTheme: _inputTheme(const Color(0xFF616161), const Color(0xFFF5F5F5)),
      filledButtonTheme: _buttonTheme(const Color(0xFF212121), const Color(0xFF424242)),
    );
  }

  // ==========================================
  // SHARED COMPONENT STYLES
  // ==========================================
  
  static InputDecorationTheme _inputTheme(Color primaryColor, Color fillColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hoverColor: fillColor, // Interactive hover state for text fields
      
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), // Curvy beautiful borders
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          width: 2.5,
          color: primaryColor,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  static FilledButtonThemeData _buttonTheme(Color primary, Color secondary) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
        
        // Interactive Mouse-over and Click color transitions
        backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) return secondary;
          if (states.contains(MaterialState.pressed)) return secondary.withOpacity(0.8);
          return primary;
        }),
        
        // Interactive shadow elevations
        elevation: MaterialStateProperty.resolveWith<double>((Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) return 10;
          if (states.contains(MaterialState.pressed)) return 2;
          return 5;
        }),
        
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Pill shaped buttons
          ),
        ),
        overlayColor: MaterialStateProperty.all(Colors.white30), // Ripple effect
      ),
    );
  }
}