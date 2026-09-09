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
  bool _isPressed = false;
  int? _pressedIndex;
  double? _dragX;
  int? _hoveredIndex;
  int _lastHapticTab = 0;

  bool get _isEngaged => _isPressed || _isDragging;

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
            child: SizedBox(
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Frosted Glass Capsule Background (Clipped strictly to 30px pill)
                  Positioned.fill(
                    child: Container(
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
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Interactive Layer (Unclipped: allows liquid lens to break out above & below navbar)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                              : (_isPressed && _pressedIndex != null
                                  ? _pressedIndex! * tabWidth
                                  : targetLeft);

                          final activeTab = _isDragging
                              ? (_hoveredIndex ?? widget.currentIndex)
                              : (_isPressed && _pressedIndex != null
                                  ? _pressedIndex!
                                  : widget.currentIndex);

                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              final x = details.localPosition.dx;
                              final index = (x / tabWidth).floor().clamp(0, 2);
                              setState(() {
                                _isPressed = true;
                                _pressedIndex = index;
                              });
                              HapticFeedback.selectionClick();
                            },
                            onTapUp: (details) {
                              final x = details.localPosition.dx;
                              final index = (x / tabWidth).floor().clamp(0, 2);
                              setState(() {
                                _isPressed = false;
                                _pressedIndex = null;
                              });
                              HapticFeedback.lightImpact();
                              if (index != widget.currentIndex) {
                                widget.onNavigateToTab(index);
                              }
                            },
                            onTapCancel: () {
                              setState(() {
                                _isPressed = false;
                                _pressedIndex = null;
                              });
                            },
                            onHorizontalDragStart: (details) {
                              final x = details.localPosition.dx;
                              final hover = (x / tabWidth).floor().clamp(0, 2);
                              setState(() {
                                _isDragging = true;
                                _isPressed = false;
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
                                  : (_pressedIndex ?? widget.currentIndex);
                              setState(() {
                                _isDragging = false;
                                _isPressed = false;
                                _dragX = null;
                                _hoveredIndex = null;
                                _pressedIndex = null;
                              });
                              HapticFeedback.lightImpact();
                              if (finalTab != widget.currentIndex) {
                                widget.onNavigateToTab(finalTab);
                              }
                            },
                            onHorizontalDragCancel: () {
                              setState(() {
                                _isDragging = false;
                                _isPressed = false;
                                _dragX = null;
                                _hoveredIndex = null;
                                _pressedIndex = null;
                              });
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Liquid Glass Lens / Iridescent Bubble Indicator (Protrudes outside bar when pressed/dragging!)
                                AnimatedPositioned(
                                  duration: _isDragging
                                      ? Duration.zero
                                      : const Duration(milliseconds: 260),
                                  curve: Curves.easeOutBack,
                                  left: currentLeft,
                                  top: _isEngaged ? -5 : 0,
                                  bottom: _isEngaged ? -5 : 0,
                                  width: tabWidth,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    scale: _isEngaged ? 1.06 : 1.0,
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
                ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.symmetric(
        horizontal: _isEngaged ? 1.0 : 2.5,
        vertical: _isEngaged ? 0.0 : 1.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isEngaged ? 26 : 24),
        // Prismatic chromatic dispersion halo on glass rim (Vivid rainbow when pressed/dragging!)
        gradient: _isEngaged
            ? const SweepGradient(
                colors: [
                  Color(0xFFFFFFFF), // Specular White
                  Color(0xFF22D3EE), // Vivid Cyan
                  Color(0xFF4ADE80), // Vivid Emerald/Lime
                  Color(0xFFFACC15), // Electric Gold/Yellow
                  Color(0xFFFB923C), // Prismatic Orange
                  Color(0xFFF43F5E), // Prismatic Pink/Red
                  Color(0xFFA855F7), // Prismatic Purple
                  Color(0xFF38BDF8), // Prismatic Light Blue
                  Color(0xFFFFFFFF),
                ],
              )
            : const SweepGradient(
                colors: [
                  Color(0xB3FFFFFF),
                  Color(0x7767E8F9),
                  Color(0x77F472B6),
                  Color(0x77FDE047),
                  Color(0xB3FFFFFF),
                ],
              ),
        boxShadow: [
          if (_isEngaged) ...[
            // 3D floating elevation shadow when lens lifts off navbar
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            // Cobalt refraction glow
            BoxShadow(
              color: const Color(0xFF147CC1).withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            // Top specular rim bounce
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ] else ...[
            BoxShadow(
              color: const Color(0xFF147CC1).withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(_isEngaged ? 2.2 : 1.5), // Glass rim thickness
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_isEngaged ? 24 : 22),
          // Refractive liquid core
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: _isEngaged ? 0.98 : 0.94),
              const Color(0xFFE0F2FE)
                  .withValues(alpha: _isEngaged ? 0.85 : 0.70),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Top specular curved reflection
            Positioned(
              top: 2,
              left: 10,
              right: 10,
              height: _isEngaged ? 12 : 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: _isEngaged ? 0.95 : 0.85),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom subtle reflection arc
            if (_isEngaged)
              Positioned(
                bottom: 2,
                left: 14,
                right: 14,
                height: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
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
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: (isActive && _isEngaged) ? 1.15 : 1.0, // Optical lens magnification!
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
