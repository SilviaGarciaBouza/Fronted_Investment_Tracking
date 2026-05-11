import 'package:flutter/material.dart';

/// Clase para gestionar los temas de la app
class AppColors extends ThemeExtension<AppColors> {
  final Color snackSuccess;
  final Color snackError;
  final Color snackWarning;
  final Color pnlPositive;
  final Color pnlNegative;
  final Color danger;

  const AppColors({
    required this.snackSuccess,
    required this.snackError,
    required this.snackWarning,
    required this.pnlPositive,
    required this.pnlNegative,
    required this.danger,
  });

  @override
  AppColors copyWith({
    Color? snackSuccess,
    Color? snackError,
    Color? snackWarning,
    Color? pnlPositive,
    Color? pnlNegative,
    Color? danger,
  }) => AppColors(
    snackSuccess: snackSuccess ?? this.snackSuccess,
    snackError: snackError ?? this.snackError,
    snackWarning: snackWarning ?? this.snackWarning,
    pnlPositive: pnlPositive ?? this.pnlPositive,
    pnlNegative: pnlNegative ?? this.pnlNegative,
    danger: danger ?? this.danger,
  );

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

const _appColors = AppColors(
  snackSuccess: Color(0xFF388E3C),
  snackError: Color(0xFFD32F2F),
  snackWarning: Color(0xFFF57C00),
  pnlPositive: Colors.greenAccent,
  pnlNegative: Colors.redAccent,
  danger: Colors.redAccent,
);

class AppTheme {
  /// TEMA OSCURO
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.lightGreenAccent,
    colorScheme: ColorScheme.dark(
      primary: Colors.lightGreenAccent,
      onPrimary: Colors.black,
      surface: Colors.grey.shade900,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey.shade500,
      surfaceContainerHighest: Colors.grey.shade900,
    ),
    extensions: const [_appColors],
  );

  /// TEMA CLARO
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1B5E20),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1B5E20),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.grey.shade700,
      surfaceContainerHighest: Colors.grey.shade200,
    ),
    extensions: const [_appColors],
  );
}
