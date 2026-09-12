import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTokens {
  static const porcelain = Color(0xFFF4F5F6);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF131517);
  static const graphite = Color(0xFF333537);
  static const stone = Color(0xFF737577);
  static const mist = Color(0xFFB3B5B7);
  static const mistLight = Color(0xFFE3E4E6);
  static const magenta = Color(0xFFCC62D5);
  static const success = Color(0xFF23663A);
  static const successSurface = Color(0xFFE9F6EE);
  static const warning = Color(0xFF8A5A00);
  static const warningSurface = Color(0xFFFFF3D6);
  static const danger = Color(0xFFB42318);
  static const dangerSurface = Color(0xFFFDEBEC);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const cardRadius = 22.0;
  static const controlRadius = 18.0;
  static const badgeRadius = 6.0;
  static const minTouchTarget = 48.0;
  static const maxContentWidth = 640.0;

  // Existing screens are migrated to the semantic names in later redesign tasks.
  static const canvas = porcelain;
  static const primary = magenta;
  static const text = ink;
  static const muted = stone;
  static const border = mist;
  static const space = space16;
  static const radius = controlRadius;
  static const maxWidth = maxContentWidth;
}

@immutable
class OperationalColors extends ThemeExtension<OperationalColors> {
  const OperationalColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;

  @override
  OperationalColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
  }) => OperationalColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
  );

  @override
  OperationalColors lerp(OperationalColors? other, double t) {
    if (other == null) return this;
    return OperationalColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

const _colorScheme = ColorScheme.light(
  primary: AppTokens.magenta,
  onPrimary: AppTokens.white,
  primaryContainer: AppTokens.mistLight,
  onPrimaryContainer: AppTokens.ink,
  secondary: AppTokens.ink,
  onSecondary: AppTokens.white,
  secondaryContainer: AppTokens.mistLight,
  onSecondaryContainer: AppTokens.ink,
  tertiary: AppTokens.graphite,
  onTertiary: AppTokens.white,
  surface: AppTokens.white,
  onSurface: AppTokens.ink,
  surfaceDim: AppTokens.mistLight,
  surfaceBright: AppTokens.white,
  surfaceContainerLowest: AppTokens.white,
  surfaceContainerLow: AppTokens.porcelain,
  surfaceContainer: AppTokens.mistLight,
  surfaceContainerHigh: AppTokens.mistLight,
  surfaceContainerHighest: AppTokens.mist,
  outline: AppTokens.mist,
  outlineVariant: AppTokens.mistLight,
  error: AppTokens.danger,
  onError: AppTokens.white,
  errorContainer: AppTokens.dangerSurface,
  onErrorContainer: AppTokens.danger,
  inverseSurface: AppTokens.ink,
  onInverseSurface: AppTokens.white,
  inversePrimary: AppTokens.magenta,
  shadow: AppTokens.ink,
  scrim: AppTokens.ink,
);

const _operationalColors = OperationalColors(
  success: AppTokens.successSurface,
  onSuccess: AppTokens.success,
  warning: AppTokens.warningSurface,
  onWarning: AppTokens.warning,
  danger: AppTokens.dangerSurface,
  onDanger: AppTokens.danger,
);

const _controlShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.controlRadius)),
);

const _cardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.cardRadius)),
  side: BorderSide(color: AppTokens.mist),
);

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.controlRadius)),
  borderSide: BorderSide(color: AppTokens.mist),
);

const _focusedInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.controlRadius)),
  borderSide: BorderSide(color: AppTokens.magenta, width: 2),
);

const _errorInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.controlRadius)),
  borderSide: BorderSide(color: AppTokens.danger),
);

const _focusedErrorInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppTokens.controlRadius)),
  borderSide: BorderSide(color: AppTokens.danger, width: 2),
);

ThemeData maintenanceTheme() {
  final typography = Typography.material2021(platform: TargetPlatform.android);
  final baseTextTheme = typography.black.apply(
    bodyColor: AppTokens.ink,
    displayColor: AppTokens.ink,
  );
  final textTheme = baseTextTheme.copyWith(
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      color: AppTokens.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      color: AppTokens.ink,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      color: AppTokens.ink,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppTokens.ink),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppTokens.graphite),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      color: AppTokens.ink,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      color: AppTokens.stone,
      fontWeight: FontWeight.w600,
    ),
  );
  final navigationLabel = textTheme.labelMedium?.copyWith(
    color: AppTokens.stone,
  );
  final selectedNavigationLabel = navigationLabel?.copyWith(
    color: AppTokens.ink,
    fontWeight: FontWeight.w700,
  );
  const navigationIcon = IconThemeData(color: AppTokens.stone);
  const selectedNavigationIcon = IconThemeData(color: AppTokens.ink);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppTokens.porcelain,
    canvasColor: AppTokens.porcelain,
    typography: typography,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: const <ThemeExtension<dynamic>>[_operationalColors],
    appBarTheme: AppBarTheme(
      backgroundColor: AppTokens.porcelain,
      foregroundColor: AppTokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTokens.white,
      indicatorColor: AppTokens.mistLight,
      elevation: 3,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? selectedNavigationLabel
            : navigationLabel,
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? selectedNavigationIcon
            : navigationIcon,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppTokens.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _cardShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space16,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.stone),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: AppTokens.magenta,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.stone),
      errorStyle: textTheme.bodySmall?.copyWith(color: AppTokens.danger),
      prefixIconColor: AppTokens.stone,
      suffixIconColor: AppTokens.stone,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _focusedInputBorder,
      errorBorder: _errorInputBorder,
      focusedErrorBorder: _focusedErrorInputBorder,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.white,
      selectedColor: AppTokens.mistLight,
      disabledColor: AppTokens.mistLight,
      side: const BorderSide(color: AppTokens.mist),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.badgeRadius)),
      ),
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppTokens.ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTokens.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.white),
      actionTextColor: AppTokens.magenta,
      disabledActionTextColor: AppTokens.mist,
      closeIconColor: AppTokens.white,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      shape: _controlShape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppTokens.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: _cardShape,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTokens.white,
      modalBackgroundColor: AppTokens.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      modalElevation: 6,
      showDragHandle: true,
      dragHandleColor: AppTokens.mist,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.cardRadius),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppTokens.magenta,
        foregroundColor: AppTokens.white,
        disabledBackgroundColor: AppTokens.mistLight,
        disabledForegroundColor: AppTokens.stone,
        minimumSize: const Size(
          AppTokens.minTouchTarget,
          AppTokens.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space24,
          vertical: AppTokens.space12,
        ),
        elevation: 0,
        textStyle: textTheme.labelLarge,
        shape: _controlShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.ink,
        disabledForegroundColor: AppTokens.mist,
        minimumSize: const Size(
          AppTokens.minTouchTarget,
          AppTokens.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space24,
          vertical: AppTokens.space12,
        ),
        side: const BorderSide(color: AppTokens.mist),
        textStyle: textTheme.labelLarge,
        shape: _controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.ink,
        disabledForegroundColor: AppTokens.mist,
        minimumSize: const Size(
          AppTokens.minTouchTarget,
          AppTokens.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
        textStyle: textTheme.labelLarge,
        shape: _controlShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppTokens.ink,
        disabledForegroundColor: AppTokens.mist,
        minimumSize: const Size.square(AppTokens.minTouchTarget),
        padding: const EdgeInsets.all(AppTokens.space12),
        shape: _controlShape,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppTokens.mistLight,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppTokens.magenta,
      linearTrackColor: AppTokens.mistLight,
      circularTrackColor: AppTokens.mistLight,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppTokens.mistLight
            : states.contains(WidgetState.selected)
            ? AppTokens.magenta
            : null,
      ),
      checkColor: const WidgetStatePropertyAll(AppTokens.white),
      side: const BorderSide(color: AppTokens.mist, width: 2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.space4)),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppTokens.mist
            : states.contains(WidgetState.selected)
            ? AppTokens.magenta
            : AppTokens.stone,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppTokens.mist
            : AppTokens.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppTokens.mistLight
            : states.contains(WidgetState.selected)
            ? AppTokens.magenta
            : AppTokens.mist,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppTokens.stone,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppTokens.magenta,
      selectionColor: AppTokens.magenta.withValues(alpha: 0.24),
      selectionHandleColor: AppTokens.magenta,
    ),
  );
}
