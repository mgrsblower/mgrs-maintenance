import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

@Deprecated(
  'Use MgrsColors, MgrsSpacing, MgrsRadii, and MgrsSizes instead.',
)
abstract final class AppTokens {
  static const canvas = MgrsColors.canvas;
  static const primary = MgrsColors.action;
  static const text = MgrsColors.ink;
  static const muted = MgrsColors.muted;
  static const border = MgrsColors.line;
  static const danger = MgrsColors.danger;
  static const success = MgrsColors.success;
  static const warning = MgrsColors.warning;
  static const accentLime = MgrsColors.successSoft;
  static const darkSlate = MgrsColors.ink;
  static const space = MgrsSpacing.base;
  static const radius = MgrsRadii.control;
  static const maxWidth = MgrsSizes.maxContentWidth;
}

ThemeData maintenanceTheme() {
  const buttonTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    canvasColor: MgrsColors.canvas,
    scaffoldBackgroundColor: MgrsColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: MgrsColors.action,
      onPrimary: MgrsColors.surface,
      secondary: MgrsColors.operational,
      onSecondary: MgrsColors.surface,
      surface: MgrsColors.surface,
      onSurface: MgrsColors.ink,
      onSurfaceVariant: MgrsColors.muted,
      error: MgrsColors.danger,
      onError: MgrsColors.surface,
      errorContainer: MgrsColors.dangerSoft,
      onErrorContainer: MgrsColors.danger,
      outline: MgrsColors.line,
      outlineVariant: MgrsColors.line,
    ),
    textTheme: const TextTheme(
      labelLarge: buttonTextStyle,
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MgrsColors.canvas,
      foregroundColor: MgrsColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: MgrsSizes.appBar,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: MgrsColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MgrsColors.surface,
      constraints: const BoxConstraints(minHeight: MgrsSizes.minTouch),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MgrsRadii.control),
        borderSide: const BorderSide(color: MgrsColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          MgrsSizes.minTouch,
          MgrsSizes.primaryButton,
        ),
        padding: const EdgeInsets.symmetric(horizontal: MgrsSpacing.lg),
        backgroundColor: MgrsColors.action,
        foregroundColor: MgrsColors.surface,
        textStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MgrsRadii.pill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.square(MgrsSizes.minTouch),
        textStyle: buttonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size.square(MgrsSizes.minTouch),
        textStyle: buttonTextStyle,
      ),
    ),
    cardTheme: CardThemeData(
      color: MgrsColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
    ),
  );
}
