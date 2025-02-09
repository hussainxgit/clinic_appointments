import 'package:flutter/material.dart';

class MyTheme {
  static const Color lightGray = Color(0xFFF6F7F9);
  static const Color lightBlue = Color.fromARGB(255, 132, 179, 255);
  static const Color blue = Color.fromARGB(255, 32, 76, 146);
  static const Color blueDark = Color(0xFF051E34);
  static const Color gray = Color(0xFF5F6368);
  static const Color yellow = Color(0xFFFFC107);
  static const Color success = Color.fromARGB(255, 139, 255, 7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: blue,
      cardColor: lightGray,
      dividerColor: gray,
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: yellow),
      dividerTheme: const DividerThemeData(color: gray),
      primaryColorDark: blueDark,
      scaffoldBackgroundColor: lightGray,
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: blueDark,
        unselectedIconTheme: IconThemeData(
          color: lightGray,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: lightGray,
        ),
        selectedIconTheme: IconThemeData(
          color: lightGray,
        ),
        selectedLabelTextStyle: TextStyle(
          color: lightBlue,
        ),
      ),
      appBarTheme: const AppBarTheme(
        shadowColor: gray,
        backgroundColor: lightGray,
        titleTextStyle: TextStyle(
          color: blueDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: blueDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: gray,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: blue,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: yellow,
      ),
      iconTheme: const IconThemeData(
        color: gray,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: blueDark,
        selectedItemColor: yellow,
        unselectedItemColor: lightGray,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: blueDark, width: 0.0),
        ),
        fillColor: blueDark,
        focusColor: blueDark,
      ),
      dataTableTheme: const DataTableThemeData(
        dividerThickness: 0.5,
      ),
    );
  }
}
