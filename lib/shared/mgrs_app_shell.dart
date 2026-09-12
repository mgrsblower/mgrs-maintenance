import 'package:flutter/material.dart';

import '../app/gateway.dart';
import 'mgrs_components.dart';

/// Shared application frame for both MGRS workspaces.
class MGRSAppShell extends StatelessWidget {
  const MGRSAppShell({
    super.key,
    required this.workspace,
    required this.user,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.onWorkspaceChanged,
  });

  final MgrsWorkspace workspace;
  final UserProfile user;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final ValueChanged<MgrsWorkspace>? onWorkspaceChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final expanded = constraints.maxWidth >= 600;
      final navigation = AdaptiveNavigation(
        workspace: workspace,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        useRail: expanded,
      );
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user.productRole == ProductRole.admin &&
              onWorkspaceChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: WorkspaceSwitcher(
                  workspace: workspace,
                  onWorkspaceChanged: onWorkspaceChanged!,
                ),
              ),
            ),
          Expanded(child: child),
        ],
      );

      return Semantics(
        container: true,
        label: '${workspace.label}. Pengguna: ${user.displayName}',
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: expanded
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [navigation, Expanded(child: content)],
                )
              : content,
          bottomNavigationBar: expanded ? null : navigation,
        ),
      );
    },
  );
}
