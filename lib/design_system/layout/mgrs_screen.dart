import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

class MgrsScreen extends StatelessWidget {
  const MgrsScreen({
    super.key,
    required this.child,
    this.scrollable = true,
    this.controller,
    this.physics,
  });

  final Widget child;
  final bool scrollable;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MgrsColors.canvas,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalGutter = math.min(
            MgrsSpacing.lg,
            constraints.maxWidth / 2,
          );
          final double contentWidth = math.min(
            MgrsSizes.maxContentWidth,
            math.max(0.0, constraints.maxWidth - horizontalGutter * 2),
          );
          final bottomPadding =
              MgrsSpacing.lg + MediaQuery.viewInsetsOf(context).bottom;
          final content = Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: contentWidth, child: child),
          );

          if (!scrollable) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalGutter,
                0,
                horizontalGutter,
                bottomPadding,
              ),
              child: content,
            );
          }

          return SingleChildScrollView(
            controller: controller,
            physics: physics,
            padding: EdgeInsets.fromLTRB(
              horizontalGutter,
              0,
              horizontalGutter,
              bottomPadding,
            ),
            child: content,
          );
        },
      ),
    ),
  );
}
