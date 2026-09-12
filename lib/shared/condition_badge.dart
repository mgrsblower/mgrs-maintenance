import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class ConditionBadge extends StatelessWidget {
  const ConditionBadge(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final operational = Theme.of(context).extension<OperationalColors>()!;
    final Color background;
    final Color foreground;
    if (value == 'OK') {
      background = operational.success;
      foreground = operational.onSuccess;
    } else if (value == 'Rusak Ringan') {
      background = operational.warning;
      foreground = operational.onWarning;
    } else {
      background = operational.danger;
      foreground = operational.onDanger;
    }

    return Chip(
      avatar: Icon(
        value == 'OK' ? Icons.check_circle_outline : Icons.info_outline,
        color: foreground,
        size: 18,
      ),
      label: Text(
        value,
        style: textTheme.labelMedium?.copyWith(color: foreground),
      ),
      side: BorderSide(color: foreground.withValues(alpha: 0.3)),
      backgroundColor: background,
    );
  }
}
