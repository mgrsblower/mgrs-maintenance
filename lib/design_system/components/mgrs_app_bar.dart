import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

@immutable
class MgrsAppBarAction {
  const MgrsAppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : assert(tooltip != '');

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class MgrsDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MgrsDetailAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.backTooltip = 'Kembali',
    this.actions = const [],
  }) : assert(backTooltip != '');

  final String title;
  final VoidCallback? onBack;
  final String backTooltip;
  final List<MgrsAppBarAction> actions;

  @override
  Size get preferredSize => const Size.fromHeight(MgrsSizes.appBar);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: MgrsSizes.appBar,
    centerTitle: true,
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    leadingWidth: MgrsSizes.appBar,
    leading: Center(
      child: Semantics(
        label: backTooltip,
        button: true,
        excludeSemantics: true,
        onTap: onBack ?? () => Navigator.maybePop(context),
        child: IconButton(
          tooltip: backTooltip,
          constraints: const BoxConstraints.tightFor(
            width: MgrsSizes.minTouch,
            height: MgrsSizes.minTouch,
          ),
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
    ),
    actions: actions.isEmpty
        ? const [SizedBox(width: MgrsSizes.appBar)]
        : actions
              .map(
                (action) => SizedBox(
                  width: MgrsSizes.appBar,
                  child: Center(
                    child: Semantics(
                      label: action.tooltip,
                      button: true,
                      excludeSemantics: true,
                      onTap: action.onPressed,
                      child: IconButton(
                        tooltip: action.tooltip,
                        constraints: const BoxConstraints.tightFor(
                          width: MgrsSizes.minTouch,
                          height: MgrsSizes.minTouch,
                        ),
                        onPressed: action.onPressed,
                        icon: Icon(action.icon),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
  );
}
