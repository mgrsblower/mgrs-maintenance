import 'package:flutter/material.dart';

/// Semantic design tokens shared by every MGRS workspace.
abstract final class AppTokens {
  static const canvas = Color(0xFFFFFFFF);
  static const canvasSubtle = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFAFAFC);
  static const surfaceStrong = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF272729);
  static const surfaceBlack = Color(0xFF1D1D1F);
  static const ink = Color(0xFF1D1D1F);
  static const inkOnDark = Color(0xFFFFFFFF);
  static const inkMuted = Color(0xFF6E6E73);
  static const divider = Color(0xFFE0E0E0);
  static const actionBlue = Color(0xFF0066CC);
  static const actionBlueFocus = Color(0xFF0071E3);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFF956400);
  static const danger = Color(0xFFB42318);

  static const space = 16.0;
  static const radius = 12.0;
  static const maxWidth = 720.0;

  // Compatibility names used by screens that have not migrated to semantic
  // tokens yet. They intentionally point at the new design roles.
  static const primary = actionBlue;
  static const text = ink;
  static const muted = inkMuted;
  static const border = divider;
}

ThemeData maintenanceTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.actionBlue,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
    onPrimary: AppTokens.inkOnDark,
    primaryContainer: isDark ? AppTokens.surfaceDark : AppTokens.canvasSubtle,
    onPrimaryContainer: isDark ? AppTokens.inkOnDark : AppTokens.ink,
    secondary: isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
    onSecondary: AppTokens.inkOnDark,
    surface: isDark ? AppTokens.surfaceDark : AppTokens.surface,
    onSurface: isDark ? AppTokens.inkOnDark : AppTokens.ink,
    surfaceContainerHighest:
        isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
    outline: isDark ? AppTokens.inkMuted : AppTokens.divider,
    error: AppTokens.danger,
    onError: AppTokens.inkOnDark,
  );
  final textTheme = _textTheme(isDark);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppTokens.radius),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTokens.radius),
    borderSide: BorderSide(
      color: isDark ? AppTokens.inkMuted : AppTokens.divider,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
    canvasColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
    dividerColor: isDark ? AppTokens.inkMuted : AppTokens.divider,
    focusColor: AppTokens.actionBlueFocus,
    hoverColor: isDark
        ? AppTokens.actionBlueFocus.withValues(alpha: .12)
        : AppTokens.actionBlue.withValues(alpha: .08),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
      foregroundColor: isDark ? AppTokens.inkOnDark : AppTokens.ink,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppTokens.actionBlueFocus, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppTokens.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        color: isDark ? AppTokens.inkOnDark : AppTokens.inkMuted,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppTokens.actionBlue,
        foregroundColor: AppTokens.inkOnDark,
        shape: shape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppTokens.actionBlue,
        foregroundColor: AppTokens.inkOnDark,
        elevation: 0,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: isDark ? AppTokens.inkOnDark : AppTokens.actionBlue,
        side: const BorderSide(color: AppTokens.actionBlue),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor:
            isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
      shape: shape.copyWith(
        side: BorderSide(color: isDark ? AppTokens.inkMuted : AppTokens.divider),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvasSubtle,
      side: BorderSide(color: isDark ? AppTokens.inkMuted : AppTokens.divider),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      labelStyle: textTheme.labelLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceBlack,
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: AppTokens.inkOnDark),
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
      shape: shape,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvas,
      indicatorColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      height: 80,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvas,
      indicatorColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
      selectedIconTheme: const IconThemeData(color: AppTokens.actionBlue),
      selectedLabelTextStyle: const TextStyle(
        color: AppTokens.actionBlue,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

ThemeData maintenanceLightTheme() => maintenanceTheme();

ThemeData maintenanceDarkTheme() =>
    maintenanceTheme(brightness: Brightness.dark);

TextTheme _textTheme(bool isDark) {
  final color = isDark ? AppTokens.inkOnDark : AppTokens.ink;
  return Typography.material2021().black.apply(
    bodyColor: color,
    displayColor: color,
  ).copyWith(
    displayLarge: TextStyle(
      fontSize: 40,
      height: 1.1,
      fontWeight: FontWeight.w600,
      letterSpacing: -1,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: color,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: color),
    bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: color),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: isDark ? AppTokens.inkOnDark : AppTokens.inkMuted,
    ),
  );
}
