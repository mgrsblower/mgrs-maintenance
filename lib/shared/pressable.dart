import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tactile press feedback wrapper inspired by Emil Kowalski and Apple design principles.
/// Scales down subtly (default 0.975) on touch down, triggers gentle haptic feedback,
/// and springs back smoothly on release.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.975,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final bool enableHaptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool? _disableAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
      value: 0.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: widget.curve,
            reverseCurve: Curves.easeOutBack,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
    final duration = disableAnimations ? Duration.zero : widget.duration;
    _controller.duration = duration;
    _controller.reverseDuration = duration;
    if (disableAnimations && _controller.isAnimating) {
      final target = _controller.status == AnimationStatus.forward ? 1.0 : 0.0;
      _controller.stop();
      _controller.value = target;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled ||
        (widget.onTap == null && widget.onLongPress == null)) {
      return;
    }
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    if (!interactive) return widget.child;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
