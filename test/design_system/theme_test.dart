import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foundation tokens expose the approved visual contract', () {
    expect(MgrsColors.canvas, const Color(0xFFF5F5F5));
    expect(MgrsColors.surface, const Color(0xFFFFFFFF));
    expect(MgrsColors.ink, const Color(0xFF171717));
    expect(MgrsColors.muted, const Color(0xFF666666));
    expect(MgrsColors.line, const Color(0xFFE7E7E7));
    expect(MgrsColors.action, const Color(0xFFD91C48));
    expect(MgrsColors.operational, const Color(0xFF147CC1));
    expect(MgrsColors.success, const Color(0xFF166534));
    expect(MgrsColors.successSoft, const Color(0xFFECF8F0));
    expect(MgrsColors.warning, const Color(0xFF854D0E));
    expect(MgrsColors.warningSoft, const Color(0xFFFEFCE8));
    expect(MgrsColors.danger, const Color(0xFFB42318));
    expect(MgrsColors.dangerSoft, const Color(0xFFFEF0EE));

    expect(MgrsSpacing.xs, 4);
    expect(MgrsSpacing.sm, 8);
    expect(MgrsSpacing.md, 12);
    expect(MgrsSpacing.base, 16);
    expect(MgrsSpacing.lg, 20);
    expect(MgrsSpacing.xl, 24);
    expect(MgrsSpacing.section, 32);

    expect(MgrsRadii.control, 12);
    expect(MgrsRadii.compact, 16);
    expect(MgrsRadii.card, 24);
    expect(MgrsRadii.sheet, 28);
    expect(MgrsRadii.pill, 999);

    expect(MgrsSizes.minTouch, 48);
    expect(MgrsSizes.appBar, 56);
    expect(MgrsSizes.primaryButton, 52);
    expect(MgrsSizes.bottomNavigation, 68);
    expect(MgrsSizes.maxContentWidth, 640);
  });

  test('legacy aliases delegate to canonical tokens', () {
    expect(AppTokens.canvas, MgrsColors.canvas);
    expect(AppTokens.primary, MgrsColors.action);
    expect(AppTokens.text, MgrsColors.ink);
    expect(AppTokens.muted, MgrsColors.muted);
    expect(AppTokens.border, MgrsColors.line);
    expect(AppTokens.danger, MgrsColors.danger);
    expect(AppTokens.success, MgrsColors.success);
    expect(AppTokens.warning, MgrsColors.warning);
    expect(AppTokens.accentLime, MgrsColors.successSoft);
    expect(AppTokens.darkSlate, MgrsColors.ink);
    expect(AppTokens.space, MgrsSpacing.base);
    expect(AppTokens.radius, MgrsRadii.control);
    expect(AppTokens.maxWidth, MgrsSizes.maxContentWidth);
  });

  test('theme exposes the approved colors and typography', () {
    final theme = maintenanceTheme();

    expect(theme.scaffoldBackgroundColor, MgrsColors.canvas);
    expect(theme.canvasColor, MgrsColors.canvas);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, MgrsColors.action);
    expect(theme.colorScheme.onPrimary, MgrsColors.surface);
    expect(theme.colorScheme.secondary, MgrsColors.operational);
    expect(theme.colorScheme.onSecondary, MgrsColors.surface);
    expect(theme.colorScheme.surface, MgrsColors.surface);
    expect(theme.colorScheme.onSurface, MgrsColors.ink);
    expect(theme.colorScheme.onSurfaceVariant, MgrsColors.muted);
    expect(theme.colorScheme.error, MgrsColors.danger);
    expect(theme.colorScheme.onError, MgrsColors.surface);
    expect(theme.colorScheme.errorContainer, MgrsColors.dangerSoft);
    expect(theme.colorScheme.onErrorContainer, MgrsColors.danger);
    expect(theme.colorScheme.outline, MgrsColors.line);
    expect(theme.colorScheme.outlineVariant, MgrsColors.line);

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(theme.textTheme.bodyMedium?.fontSize, 14);
    expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
    expect(theme.textTheme.labelLarge?.fontFamily, 'Inter');
    expect(theme.textTheme.labelLarge?.fontSize, 15);
    expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.labelMedium?.fontFamily, 'Inter');
    expect(theme.textTheme.labelMedium?.fontSize, 12);
    expect(theme.textTheme.labelMedium?.fontWeight, FontWeight.w600);
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Inter');
    expect(theme.appBarTheme.titleTextStyle?.fontSize, 17);
    expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w600);

    final buttonStyle = theme.filledButtonTheme.style!;
    final buttonTextStyle = buttonStyle.textStyle!.resolve(<WidgetState>{});
    expect(buttonTextStyle?.fontFamily, 'Inter');
    expect(buttonTextStyle?.fontSize, 15);
    expect(buttonTextStyle?.fontWeight, FontWeight.w600);
  });

  test('theme exposes the approved component geometry', () {
    final theme = maintenanceTheme();
    final buttonStyle = theme.filledButtonTheme.style!;
    final buttonStates = <WidgetState>{};

    expect(
      buttonStyle.minimumSize!.resolve(buttonStates),
      const Size(MgrsSizes.minTouch, MgrsSizes.primaryButton),
    );
    expect(buttonStyle.backgroundColor!.resolve(buttonStates), MgrsColors.action);
    expect(buttonStyle.foregroundColor!.resolve(buttonStates), MgrsColors.surface);
    expect(
      (buttonStyle.shape!.resolve(buttonStates) as RoundedRectangleBorder)
          .borderRadius,
      BorderRadius.circular(MgrsRadii.pill),
    );

    final inputTheme = theme.inputDecorationTheme;
    expect(inputTheme.filled, isTrue);
    expect(inputTheme.fillColor, MgrsColors.surface);
    expect(
      inputTheme.constraints,
      const BoxConstraints(minHeight: MgrsSizes.minTouch),
    );
    final inputBorder = inputTheme.border! as OutlineInputBorder;
    expect(inputBorder.borderRadius, BorderRadius.circular(MgrsRadii.control));
    expect(inputBorder.borderSide, const BorderSide(color: MgrsColors.line));

    expect(theme.cardTheme.color, MgrsColors.surface);
    expect(theme.cardTheme.elevation, 0);
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, BorderRadius.circular(MgrsRadii.card));
    expect(cardShape.side, BorderSide.none);

    expect(theme.appBarTheme.toolbarHeight, MgrsSizes.appBar);
  });

  test('the official Inter family and license are bundled', () async {
    const fontAsset = 'assets/fonts/Inter-Variable.ttf';
    final fontManifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    final interFamily = fontManifest.cast<Map<String, dynamic>>().singleWhere(
      (entry) => entry['family'] == 'Inter',
    );
    final interFonts = interFamily['fonts']! as List<dynamic>;
    expect(
      interFonts.any(
        (entry) =>
            (entry as Map<String, dynamic>)['asset'] == fontAsset,
      ),
      isTrue,
    );

    final font = await rootBundle.load(fontAsset);
    expect(font.getUint32(0), 0x00010000);

    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    expect(
      license,
      contains('SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007'),
    );
  });
}
