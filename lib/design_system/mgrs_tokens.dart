import 'package:flutter/material.dart';

abstract final class MgrsColors {
  static const canvas = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF666666);
  static const line = Color(0xFFE7E7E7);
  static const action = Color(0xFFD91C48);
  static const operational = Color(0xFF147CC1);
  static const success = Color(0xFF166534);
  static const successSoft = Color(0xFFECF8F0);
  static const warning = Color(0xFF854D0E);
  static const warningSoft = Color(0xFFFEFCE8);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF0EE);
}

abstract final class MgrsSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0, base = 16.0;
  static const lg = 20.0, xl = 24.0, section = 32.0;
}

abstract final class MgrsRadii {
  static const control = 12.0, compact = 16.0, card = 24.0;
  static const sheet = 28.0, pill = 999.0;
}

abstract final class MgrsSizes {
  static const minTouch = 48.0, appBar = 56.0;
  static const primaryButton = 52.0, bottomNavigation = 68.0;
  static const maxContentWidth = 640.0;
}
