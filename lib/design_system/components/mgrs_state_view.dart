import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_button.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

enum _MgrsStateKind { loading, empty, error, noResults }

class MgrsStateView extends StatelessWidget {
  const MgrsStateView.loading({super.key, this.title = 'Memuat data...'})
    : _kind = _MgrsStateKind.loading,
      message = null,
      actionLabel = null,
      onAction = null,
      query = null,
      onReset = null;

  const MgrsStateView.empty({
    super.key,
    required this.title,
    required this.actionLabel,
    this.message,
    this.onAction,
  }) : _kind = _MgrsStateKind.empty,
       query = null,
       onReset = null;

  const MgrsStateView.error({
    super.key,
    required this.title,
    required this.actionLabel,
    this.message,
    this.onAction,
  }) : _kind = _MgrsStateKind.error,
       query = null,
       onReset = null;

  const MgrsStateView.noResults({
    super.key,
    required this.query,
    required VoidCallback onReset,
  }) : _kind = _MgrsStateKind.noResults,
       title = 'Pencarian tidak ditemukan',
       message = null,
       actionLabel = 'Hapus pencarian',
       onAction = onReset,
       onReset = onReset;

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? query;
  final VoidCallback? onReset;
  final _MgrsStateKind _kind;

  IconData get _icon => switch (_kind) {
    _MgrsStateKind.loading => Icons.sync,
    _MgrsStateKind.empty => Icons.inbox_outlined,
    _MgrsStateKind.error => Icons.cloud_off_outlined,
    _MgrsStateKind.noResults => Icons.search_off,
  };

  Color get _iconColor => switch (_kind) {
    _MgrsStateKind.error => MgrsColors.danger,
    _ => MgrsColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final recoveryLabel = actionLabel;
    final isLoading = _kind == _MgrsStateKind.loading;
    final detail = _kind == _MgrsStateKind.noResults
        ? 'Tidak ada data yang cocok dengan “$query”. Ubah atau hapus pencarian untuk melihat data lain.'
        : message;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(MgrsSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                Semantics(
                  label: title,
                  liveRegion: true,
                  child: const ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else
                Icon(_icon, size: 40, color: _iconColor),
              const SizedBox(height: MgrsSpacing.base),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MgrsColors.ink,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: MgrsSpacing.sm),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
                ),
              ],
              if (recoveryLabel != null) ...[
                const SizedBox(height: MgrsSpacing.base),
                if (onAction != null)
                  MgrsButton.neutral(label: recoveryLabel, onPressed: onAction)
                else
                  Text(
                    recoveryLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MgrsColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
