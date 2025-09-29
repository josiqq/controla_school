import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4089ff);
  static const Color accentColor = Color(0xFF4089ff);
  static const Color backgroundColor = Color(0xFFffffff);
  static const Color secondaryColor = Color(0xFFf0f0f0);
  static const Color textColor = Color(0xFF333333);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4089ff), Color(0xFF6da5ff)],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4089ff), Color(0xFF6da5ff)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: backgroundColor,
        onPrimary: backgroundColor,
        onSurface: textColor,
      ),
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Nunito',

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      ),

      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
      ).apply(
        fontFamily: 'Nunito',
      ),
    );
  }
}