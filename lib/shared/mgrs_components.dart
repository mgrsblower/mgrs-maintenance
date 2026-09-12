import 'package:flutter/material.dart';

import '../app/gateway.dart';

/// Labels and icons that define the destination contract for each workspace.
class MgrsDestination {
  const MgrsDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

extension MgrsWorkspacePresentation on MgrsWorkspace {
  String get label => switch (this) {
    MgrsWorkspace.pic => 'PIC MGRS',
    MgrsWorkspace.field => 'Tim Lapangan',
  };

  List<MgrsDestination> get destinations => switch (this) {
    MgrsWorkspace.pic => const [
      MgrsDestination(
        label: 'Beranda',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
      ),
      MgrsDestination(
        label: 'Orderan',
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note,
      ),
      MgrsDestination(
        label: 'Invoice',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
      MgrsDestination(
        label: 'Profil',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ],
    MgrsWorkspace.field => const [
      MgrsDestination(
        label: 'Scan',
        icon: Icons.qr_code_scanner_outlined,
        selectedIcon: Icons.qr_code_scanner,
      ),
      MgrsDestination(
        label: 'Berkala',
        icon: Icons.event_repeat_outlined,
        selectedIcon: Icons.event_repeat,
      ),
      MgrsDestination(
        label: 'Komponen',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
      MgrsDestination(
        label: 'Riwayat',
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
      ),
    ],
  };
}

/// Native Material navigation that adapts at the compact/expanded breakpoint.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    super.key,
    required this.workspace,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.useRail,
  });

  final MgrsWorkspace workspace;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  /// Primarily used by a parent that already measured the available width.
  /// When omitted, the component measures itself with [LayoutBuilder].
  final bool? useRail;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rail = useRail ?? constraints.maxWidth >= 600;
      final destinations = workspace.destinations;
      final index = selectedIndex.clamp(0, destinations.length - 1).toInt();
      final selected = destinations[index].label;
      final semanticsLabel =
          '${workspace.label}, destinasi aktif: $selected';
      final destinationList = [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ];
      if (rail) {
        return Semantics(
          container: true,
          label: semanticsLabel,
          child: NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
        );
      }
      return Semantics(
        container: true,
        label: semanticsLabel,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onDestinationSelected,
          destinations: destinationList,
        ),
      );
    },
  );
}

/// The admin-only workspace choice. The two labels are intentionally fixed by
/// the product contract and do not expose legacy mode names.
class WorkspaceSwitcher extends StatelessWidget {
  const WorkspaceSwitcher({
    super.key,
    required this.workspace,
    required this.onWorkspaceChanged,
  });

  final MgrsWorkspace workspace;
  final ValueChanged<MgrsWorkspace> onWorkspaceChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Workspace aktif: ${workspace.label}',
      child: SegmentedButton<MgrsWorkspace>(
        segments: const [
          ButtonSegment<MgrsWorkspace>(
            value: MgrsWorkspace.pic,
            label: Text('PIC MGRS'),
            icon: Icon(Icons.assignment_outlined),
          ),
          ButtonSegment<MgrsWorkspace>(
            value: MgrsWorkspace.field,
            label: Text('Tim Lapangan'),
            icon: Icon(Icons.build_outlined),
          ),
        ],
        selected: {workspace},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty && selection.first != workspace) {
            onWorkspaceChanged(selection.first);
          }
        },
      ),
    );
  }
}

/// A persistent form action area that owns saving, disabled, and retry states.
/// The form remains responsible for validation and submission semantics.
class SaveActionBar extends StatelessWidget {
  const SaveActionBar({
    super.key,
    required this.onSave,
    this.isSubmitting = false,
    this.isDisabled = false,
    this.onRetry,
    this.errorMessage,
    this.label = 'Simpan',
  });

  final VoidCallback? onSave;
  final bool isSubmitting;
  final bool isDisabled;
  final VoidCallback? onRetry;
  final String? errorMessage;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isSubmitting || onSave == null;
    return Semantics(
      container: true,
      label: isSubmitting ? 'Menyimpan perubahan' : 'Aksi penyimpanan',
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: disabled ? null : onSave,
                      icon: isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(isSubmitting ? 'Menyimpan…' : label),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Coba lagi',
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : onRetry,
                        child: const Text('Coba lagi'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
    );
  }
}
