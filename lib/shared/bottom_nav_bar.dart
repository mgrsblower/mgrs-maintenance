import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';

/// A role-aware destination used by [AppBottomNavBar].
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
}

/// The shared Material navigation shell for service and PIC destinations.
///
/// The navigation bar keeps Material semantics and padded touch targets, while
/// the scanner remains the single visually prominent primary action.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onNavigateToTab,
    this.onOpenScanner,
    this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback? onOpenScanner;
  final List<AppNavItem>? items;

  static const defaultItems = [
    AppNavItem(
      label: 'Beranda',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    AppNavItem(
      label: 'Aset',
      activeIcon: Icons.inventory_2_rounded,
      inactiveIcon: Icons.inventory_2_outlined,
    ),
    AppNavItem(
      label: 'Servis',
      activeIcon: Icons.build_rounded,
      inactiveIcon: Icons.build_outlined,
    ),
  ];

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  double? _dragX;
  int? _draggedIndex;

  void _selectDestination(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onNavigateToTab(index);
  }

  void _updateDrag(double x, double width, int itemCount) {
    _dragX = x.clamp(0.0, width).toDouble();
    final index = (((_dragX! / width) * itemCount).floor())
        .clamp(0, itemCount - 1)
        .toInt();
    if (_draggedIndex == index) return;
    _draggedIndex = index;
    HapticFeedback.selectionClick();
  }

  void _finishDrag() {
    final index = _draggedIndex;
    _cancelDrag();
    if (index != null) _selectDestination(index);
  }

  void _cancelDrag() {
    _dragX = null;
    _draggedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final items = widget.items ?? AppBottomNavBar.defaultItems;
    final selectedIndex = widget.currentIndex
        .clamp(0, items.length - 1)
        .toInt();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space8,
        AppTokens.space16,
        AppTokens.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (details) => _updateDrag(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  items.length,
                ),
                onHorizontalDragUpdate: (details) => _updateDrag(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  items.length,
                ),
                onHorizontalDragEnd: (_) => _finishDrag(),
                onHorizontalDragCancel: _cancelDrag,
                child: NavigationBar(
                  height: 72,
                  animationDuration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  backgroundColor: colors.surface,
                  indicatorColor: colors.secondaryContainer,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: [
                    for (final item in items)
                      NavigationDestination(
                        selectedIcon: Icon(item.activeIcon),
                        icon: Icon(item.inactiveIcon),
                        label: item.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.onOpenScanner != null) ...[
            const SizedBox(width: AppTokens.space12),
            SizedBox.square(
              dimension: 56,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: widget.onOpenScanner,
                tooltip: 'Buka pemindai QR',
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
