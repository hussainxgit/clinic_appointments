// lib/core/ui/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromARGB(255, 14, 14, 72); // Navy blue
  static const Color accentColor = Color(0xFF4285F4);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color infoColor = Color(0xFF0288D1);
  
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: accentColor,
      textTheme: ButtonTextTheme.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: infoColor,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.black54,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentColor,
      unselectedLabelColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.white70,
      selectedColor: accentColor,
      textColor: Colors.black,
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  );
}