import 'package:flutter/material.dart';

class AppTheme {
  // Define the core color palette
  static const Color _primaryColor = Color(0xFF007BFF); // A professional, clean blue
  static const Color _lightPrimaryContainer = Color(0xFFD9E9FF);
  static const Color _darkPrimaryContainer = Color(0xFF00468D);
  static const Color _lightSurface = Color(0xFFF8F9FA);
  static const Color _darkSurface = Color(0xFF121212);

  // --- Light Theme ---
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        primaryContainer: _lightPrimaryContainer,
        secondary: const Color(0xFF00A3AD),
        secondaryContainer: const Color(0xFFB3E5FC),
        surface: _lightSurface,
        background: _lightSurface,
      ),
      scaffoldBackgroundColor: _lightSurface,
      appBarTheme: const AppBarTheme(
        elevation: 0.5,
        shadowColor: Color(0x339E9E9E),
        backgroundColor: _lightSurface,
        foregroundColor: Colors.black87,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2.0,
        shadowColor: Color(0x1A000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _primaryColor, width: 2.0),
        ),
      ),
    );
  }

  // --- Dark Theme ---
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor, // <<< CORRECTED TYPO HERE
        primaryContainer: _darkPrimaryContainer,
        secondary: const Color(0xFF4DD0E1),
        secondaryContainer: const Color(0xFF005662),
        surface: _darkSurface,
        background: _darkSurface,
      ),
      scaffoldBackgroundColor: _darkSurface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 1.0,
        color: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1E1E1E),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _primaryColor, width: 2.0),
        ),
      ),
    );
  }
}
