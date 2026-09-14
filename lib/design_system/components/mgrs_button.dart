import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

enum _MgrsButtonKind { primary, neutral, destructive }

class MgrsButton extends StatelessWidget {
  const MgrsButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  }) : _kind = _MgrsButtonKind.primary;

  const MgrsButton.neutral({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  }) : _kind = _MgrsButtonKind.neutral;

  const MgrsButton.destructive({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  }) : _kind = _MgrsButtonKind.destructive;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final _MgrsButtonKind _kind;

  Color get _backgroundColor => switch (_kind) {
    _MgrsButtonKind.primary => MgrsColors.action,
    _MgrsButtonKind.neutral => MgrsColors.ink,
    _MgrsButtonKind.destructive => MgrsColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final labelContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: MgrsSpacing.sm),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return SizedBox(
      height: MgrsSizes.primaryButton,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(MgrsSizes.minTouch, MgrsSizes.primaryButton),
          padding: const EdgeInsets.symmetric(horizontal: MgrsSpacing.lg),
          backgroundColor: _backgroundColor,
          foregroundColor: MgrsColors.surface,
          disabledBackgroundColor: _backgroundColor.withValues(alpha: .56),
          disabledForegroundColor: MgrsColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MgrsRadii.pill),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: !loading,
              maintainAnimation: true,
              maintainSize: true,
              maintainState: true,
              child: labelContent,
            ),
            if (loading)
              Semantics(
                label: 'Sedang memproses $label',
                liveRegion: true,
                child: const ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: MgrsColors.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
