// ============================================
// FILE: lib/presentation/themes/app_theme.dart
// Updated with Cairo font
// ============================================

import 'package:flutter/material.dart';
import 'page_transitions.dart';

class AppTheme {
  // Primary Colors
  static const Color primary = Color(0xFF8A3A4A); // Burgundy/Mauve color
  static const Color background = Color(0xFFD8CCB2); // Beige background
  static const Color cardBackground = Colors.white;

  // Additional colors
  static const Color secondary = Color(0xFF9B7B8C);
  static const Color accent = Color(0xFFAB8B9C);
  static const Color textDark = Colors.black87;
  static const Color textLight = Colors.white;

  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      background: background,
    ),

    // Smooth page transitions on all platforms
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SmoothPageTransitionsBuilder(),
        TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.windows: SmoothPageTransitionsBuilder(),
        TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.linux: SmoothPageTransitionsBuilder(),
      },
    ),

    // Subtle tap feedback
    splashColor: primary.withOpacity(0.08),
    highlightColor: primary.withOpacity(0.04),

    // ✅ Cairo Font Family
    fontFamily: 'Cairo',

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: primary.withOpacity(0.15),
      color: cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey[400]),
      labelStyle: const TextStyle(fontFamily: 'Cairo'),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textLight,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 2,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: textDark),
      bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: textDark),
      bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: textDark),
    ),
  );
}
