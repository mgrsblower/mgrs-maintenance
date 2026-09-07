import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const canvas = Color(0xFFF4F8FC),
      primary = Color(0xFF147CC1),
      text = Color(0xFF141820),
      muted = Color(0xFF667085),
      border = Color(0xFFDDE2E8),
      danger = Color(0xFFB42318),
      success = Color(0xFF137333),
      warning = Color(0xFF9A6700),
      accentLime = Color(0xFFCEF284),
      darkSlate = Color(0xFF0F172A);
  static const space = 16.0, radius = 12.0, maxWidth = 640.0;
}

ThemeData maintenanceTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppTokens.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTokens.primary,
    primary: AppTokens.primary,
    surface: Colors.white,
    onSurface: AppTokens.text,
    error: AppTokens.danger,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppTokens.canvas,
    scrolledUnderElevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: const BorderSide(color: AppTokens.border),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      side: const BorderSide(color: AppTokens.border),
    ),
  ),
);
