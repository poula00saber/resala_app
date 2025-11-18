import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF8A3A4A);
  static const Color background = Color(0xFFD8CCB2);

  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: primary,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 18,
        color: primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
