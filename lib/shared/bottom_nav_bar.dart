import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pressable.dart';

/// Elevated Liquid Glass operational bottom navigation dock for MGRS Maintenance.
/// Features:
/// 1. Interactive Drag-to-Scrub gesture (press and slide across tabs with live 1:1 tracking)
/// 2. Liquid Glass Bubble Lens indicator with chromatic aberration / iridescent rainbow refraction rim
/// 3. Tactile spring release snapping (Curves.easeOutBack) with tick haptic feedback
/// 4. Prominent cobalt hero QR scanner action button
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onNavigateToTab,
    required this.onOpenScanner,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenScanner;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  bool _isDragging = false;
  double? _dragX;
  int? _hoveredIndex;
  int _lastHapticTab = 0;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      child: Row(
        children: [
          // Elevated Frosted Glass Capsule Nav Bar
          Expanded(
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 18,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final tabWidth = totalWidth / 3;

                        // Target position based on active or dragged tab
                        final targetLeft =
                            widget.currentIndex.clamp(0, 2) * tabWidth;
                        final currentLeft = _isDragging && _dragX != null
                            ? (_dragX! - tabWidth / 2)
                                .clamp(0.0, totalWidth - tabWidth)
                            : targetLeft;

                        final activeTab = _isDragging
                            ? (_hoveredIndex ?? widget.currentIndex)
                            : widget.currentIndex;

                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (details) {
                            final x = details.localPosition.dx;
                            final hover = (x / tabWidth).floor().clamp(0, 2);
                            setState(() {
                              _isDragging = true;
                              _dragX = x;
                              _hoveredIndex = hover;
                              _lastHapticTab = hover;
                            });
                            HapticFeedback.selectionClick();
                          },
                          onHorizontalDragUpdate: (details) {
                            final x = details.localPosition.dx;
                            final hover = (x / tabWidth).floor().clamp(0, 2);
                            if (hover != _lastHapticTab) {
                              HapticFeedback.selectionClick();
                              _lastHapticTab = hover;
                            }
                            setState(() {
                              _dragX = x;
                              _hoveredIndex = hover;
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            final finalTab = _dragX != null
                                ? (_dragX! / tabWidth).floor().clamp(0, 2)
                                : widget.currentIndex;
                            setState(() {
                              _isDragging = false;
                              _dragX = null;
                              _hoveredIndex = null;
                            });
                            HapticFeedback.lightImpact();
                            if (finalTab != widget.currentIndex) {
                              widget.onNavigateToTab(finalTab);
                            }
                          },
                          onHorizontalDragCancel: () {
                            setState(() {
                              _isDragging = false;
                              _dragX = null;
                              _hoveredIndex = null;
                            });
                          },
                          child: Stack(
                            children: [
                              // Liquid Glass Lens / Iridescent Bubble Indicator
                              AnimatedPositioned(
                                duration: _isDragging
                                    ? Duration.zero
                                    : const Duration(milliseconds: 320),
                                curve: Curves.easeOutBack,
                                left: currentLeft,
                                top: 0,
                                bottom: 0,
                                width: tabWidth,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 150),
                                  scale: _isDragging ? 1.05 : 1.0,
                                  child: _buildLiquidGlassBubble(),
                                ),
                              ),

                              // Tab items row
                              Row(
                                children: [
                                  _buildTab(
                                    index: 0,
                                    label: 'Beranda',
                                    activeIcon: Icons.home_rounded,
                                    inactiveIcon: Icons.home_outlined,
                                    currentActiveTab: activeTab,
                                  ),
                                  _buildTab(
                                    index: 1,
                                    label: 'Aset',
                                    activeIcon: Icons.inventory_2_rounded,
                                    inactiveIcon: Icons.inventory_2_outlined,
                                    currentActiveTab: activeTab,
                                  ),
                                  _buildTab(
                                    index: 2,
                                    label: 'Servis',
                                    activeIcon: Icons.build_rounded,
                                    inactiveIcon: Icons.build_outlined,
                                    currentActiveTab: activeTab,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Floating QR Scanner Button (MGRS Cobalt Hero Action)
          PressableScale(
            onTap: widget.onOpenScanner,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF147CC1),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33147CC1),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Iridescent chromatic dispersion halo on glass rim
        gradient: const SweepGradient(
          colors: [
            Color(0xB3FFFFFF), // Specular White
            Color(0x9967E8F9), // Iridescent Cyan
            Color(0x99F472B6), // Iridescent Pink
            Color(0x99FDE047), // Iridescent Gold
            Color(0xB3FFFFFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF147CC1)
                .withValues(alpha: _isDragging ? 0.32 : 0.18),
            blurRadius: _isDragging ? 16 : 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5), // Glass rim thickness
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // Refractive liquid core
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              const Color(0xFFE0F2FE).withValues(alpha: 0.75),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Top specular curved reflection
            Positioned(
              top: 2,
              left: 12,
              right: 12,
              height: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required int currentActiveTab,
  }) {
    final isActive = currentActiveTab == index;

    return Expanded(
      child: PressableScale(
        onTap: () => widget.onNavigateToTab(index),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  key: ValueKey<bool>(isActive),
                  size: 20,
                  color: isActive
                      ? const Color(0xFF147CC1)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF147CC1)
                      : const Color(0xFF64748B),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
