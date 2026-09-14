import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

enum MgrsStatusTone { success, warning, danger }

class MgrsStatusBadge extends StatelessWidget {
  const MgrsStatusBadge(this.value, {super.key, this.tone});

  final String value;
  final MgrsStatusTone? tone;

  _MgrsStatusStyle get _style {
    if (tone != null) {
      return switch (tone!) {
        MgrsStatusTone.success => const _MgrsStatusStyle(
          foreground: MgrsColors.success,
          background: MgrsColors.successSoft,
          icon: Icons.check_circle_outline,
        ),
        MgrsStatusTone.warning => const _MgrsStatusStyle(
          foreground: MgrsColors.warning,
          background: MgrsColors.warningSoft,
          icon: Icons.info_outline,
        ),
        MgrsStatusTone.danger => const _MgrsStatusStyle(
          foreground: MgrsColors.danger,
          background: MgrsColors.dangerSoft,
          icon: Icons.info_outline,
        ),
      };
    }
    if (value == 'OK' ||
        value == 'Layak Pakai' ||
        value == 'Layak Digunakan' ||
        value == 'Lunas') {
      return const _MgrsStatusStyle(
        foreground: MgrsColors.success,
        background: MgrsColors.successSoft,
        icon: Icons.check_circle_outline,
      );
    }
    if (value == 'Rusak Ringan' ||
        value == 'Service' ||
        value == 'Perlu Servis' ||
        value == 'needs_service' ||
        value == 'under_maintenance' ||
        value == 'Belum Diperiksa') {
      return const _MgrsStatusStyle(
        foreground: MgrsColors.warning,
        background: MgrsColors.warningSoft,
        icon: Icons.info_outline,
      );
    }
    return const _MgrsStatusStyle(
      foreground: MgrsColors.danger,
      background: MgrsColors.dangerSoft,
      icon: Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Semantics(
      container: true,
      label: 'Status kondisi: $value',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(MgrsRadii.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MgrsSpacing.md,
              vertical: MgrsSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, color: style.foreground, size: 18),
                const SizedBox(width: MgrsSpacing.sm),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: style.foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _MgrsStatusStyle {
  const _MgrsStatusStyle({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}
