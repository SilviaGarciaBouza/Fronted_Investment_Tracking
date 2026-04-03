import 'package:flutter/material.dart';

class AppTheme {
  /// TEMA OSCURO
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.lightGreenAccent,
    colorScheme: const ColorScheme.dark(
      primary: Colors.lightGreenAccent,
      onPrimary: Colors.black,
    ),
  );

  /// TEMA CLARO
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1B5E20), // Verde Bosque
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1B5E20),
      onPrimary: Colors.white,
    ),
  );
}
