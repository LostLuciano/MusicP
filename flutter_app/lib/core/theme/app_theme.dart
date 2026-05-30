import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF9D4EDD), // Electric Purple
      scaffoldBackgroundColor: const Color(0xFF0F0C1B), // Midnight Blue-Black

      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF9D4EDD),
        secondary: const Color(0xFF240046),
        surface: const Color(0xFF161224),
        error: Colors.redAccent,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161224),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      textTheme: TextTheme(
        headlineMedium: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        titleLarge: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Colors.white.withValues(alpha: 0.90),
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(color: Colors.white60, fontSize: 14),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF9D4EDD),
        inactiveTrackColor: Colors.white10,
        thumbColor: Color(0xFFE0AAFF),
        overlayColor: Color(0x299D4EDD),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9D4EDD),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
