import 'package:flutter/material.dart';

/// Zentrale Theme-Definition für die App
class AppTheme {
  // Farben
  static const Color beerBrown = Color(0xFF8B4513);
  static const Color beerGold = Color(0xFFD4AF37);
  static const Color beerAmber = Color(0xFFFF8C00);
  static const Color beerDark = Color(0xFF5C3A1F);
  static const Color beerLight = Color(0xFFFFE4B5);
  static const Color beerBlack = Color(0xFF12100E);
  static const Color beerDarkRoasted = Color(0xFF251D18);
  static const Color beerSurface = Color(0xFF1C1917);
  static const Color beerAccentGold = Color(0xFFFFD700);
  static const Color beerAccentAmber = Color(0xFFFFA000);

  /// Erstellt das Material Theme für die App
  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: beerBrown,
        primary: beerBrown,
        secondary: beerGold,
        tertiary: beerAmber,
        surface: beerLight,
        onPrimary: Colors.white,
        onSecondary: beerDark,
        onSurface: beerDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: beerBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: beerBrown,
        selectedItemColor: beerGold,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: beerBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beerBrown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beerGold, width: 2),
        ),
        filled: true,
        fillColor: beerLight.withOpacity(0.3),
      ),
      cardTheme: CardThemeData(
        color: beerLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Gradient für Bier-Hintergründe
  static const LinearGradient beerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      beerBlack,
      beerDarkRoasted,
    ],
  );

  /// Gradient für AppBar
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      beerAccentAmber,
      beerAccentGold,
    ],
  );

  /// Gradient für Bier-Karten
  static const LinearGradient beerCardGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      beerAccentAmber,
      beerAccentGold,
    ],
  );
}
