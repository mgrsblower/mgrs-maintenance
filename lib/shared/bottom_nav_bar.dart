import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

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
  bool _isDragging = false;
  int? _hoveredIndex;
  int _lastHapticTab = 0;

  List<AppNavItem> get _items => widget.items ?? AppBottomNavBar.defaultItems;

  @override
  void initState() {
    super.initState();
    _lastHapticTab = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _lastHapticTab = widget.currentIndex;
    }
  }

  int _indexForPosition(double x, double width) {
    final itemWidth = width / _items.length;
    return (x / itemWidth).floor().clamp(0, _items.length - 1);
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    if (index != widget.currentIndex) widget.onNavigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        MgrsSpacing.lg,
        MgrsSpacing.sm,
        MgrsSpacing.lg,
        MgrsSpacing.sm,
      ),
      child: SizedBox(
        key: const ValueKey('bottom-navigation-content'),
        height: MgrsSizes.bottomNavigation,
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MgrsColors.ink,
                  borderRadius: BorderRadius.circular(MgrsRadii.pill),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (details) {
                      final index = _indexForPosition(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                      setState(() {
                        _isDragging = true;
                        _hoveredIndex = index;
                        _lastHapticTab = index;
                      });
                      HapticFeedback.selectionClick();
                    },
                    onHorizontalDragUpdate: (details) {
                      final index = _indexForPosition(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                      if (index != _lastHapticTab) {
                        HapticFeedback.selectionClick();
                        _lastHapticTab = index;
                      }
                      setState(() => _hoveredIndex = index);
                    },
                    onHorizontalDragEnd: (_) {
                      final index = _hoveredIndex ?? widget.currentIndex;
                      setState(() {
                        _isDragging = false;
                        _hoveredIndex = null;
                      });
                      HapticFeedback.lightImpact();
                      if (index != widget.currentIndex) {
                        widget.onNavigateToTab(index);
                      }
                    },
                    onHorizontalDragCancel: () => setState(() {
                      _isDragging = false;
                      _hoveredIndex = null;
                    }),
                    child: Builder(
                      builder: (context) {
                        final activeIndex =
                            (_isDragging
                                ? _hoveredIndex
                                : widget.currentIndex) ??
                            widget.currentIndex;
                        final alignmentX = _items.length == 1
                            ? 0.0
                            : -1.0 + (2.0 * activeIndex / (_items.length - 1));
                        return Stack(
                          children: [
                            AnimatedAlign(
                              key: const ValueKey('navigation-snap-indicator'),
                              duration: _isDragging
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              alignment: Alignment(alignmentX, 0),
                              child: FractionallySizedBox(
                                widthFactor: 1 / _items.length,
                                heightFactor: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(MgrsSpacing.xs),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(
                                        MgrsRadii.pill,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < _items.length;
                                  index++
                                )
                                  Expanded(
                                    child: _NavigationDestination(
                                      key: ValueKey('nav-item-$index'),
                                      item: _items[index],
                                      selected: activeIndex == index,
                                      onTap: () => _select(index),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onOpenScanner != null) ...[
              const SizedBox(width: MgrsSpacing.sm),
              Semantics(
                label: 'Buka pemindai kode',
                button: true,
                excludeSemantics: true,
                onTap: widget.onOpenScanner,
                child: Tooltip(
                  message: 'Buka pemindai kode',
                  child: Material(
                    color: MgrsColors.action,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const ValueKey('scanner-action'),
                      customBorder: const CircleBorder(),
                      focusColor: Colors.white24,
                      onTap: widget.onOpenScanner,
                      child: const SizedBox.square(
                        dimension: 56,
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: MgrsColors.surface,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MgrsRadii.pill),
          focusColor: Colors.white24,
          hoverColor: Colors.white10,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            scale: selected ? 1.04 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.all(MgrsSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MgrsRadii.pill),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.inactiveIcon,
                    size: 21,
                    color: selected
                        ? MgrsColors.surface
                        : const Color(0xFFA8A8A8),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? MgrsColors.surface
                          : const Color(0xFFA8A8A8),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
