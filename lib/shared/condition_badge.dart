import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class ConditionBadge extends StatelessWidget {
  const ConditionBadge(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) {
    final color = value == 'OK'
        ? AppTokens.success
        : value == 'Rusak Ringan'
        ? AppTokens.warning
        : AppTokens.danger;
    return Chip(
      avatar: Icon(
        value == 'OK' ? Icons.check_circle_outline : Icons.info_outline,
        color: color,
        size: 18,
      ),
      label: Text(value, style: TextStyle(color: color)),
      side: BorderSide(color: color.withValues(alpha: .3)),
      backgroundColor: color.withValues(alpha: .06),
    );
  }
}
