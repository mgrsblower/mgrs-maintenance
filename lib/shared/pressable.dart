import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tactile press feedback wrapper inspired by Emil Kowalski and Apple design principles.
/// Scales down subtly (default 0.975) on touch down, triggers gentle haptic feedback,
/// and springs back smoothly on release.
/// Provides accessible Material press feedback for custom content.
///
/// Use a real Material button when the control is a button. This wrapper is
/// intended for cards and other custom surfaces that still need tap semantics.
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
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final bool enableHaptic;
  final String? tooltip;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _hasAction => widget.onTap != null || widget.onLongPress != null;
  bool get _isInteractive => widget.enabled && _hasAction;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
      value: 0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    if (widget.enableHaptic) HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    _controller.reverse();
  }

  Widget _materialChild(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final child = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _isInteractive ? widget.onTap : null,
        onLongPress: _isInteractive ? widget.onLongPress : null,
        onTapDown: _isInteractive ? _handleTapDown : null,
        onTapUp: _isInteractive ? _handleTapUp : null,
        onTapCancel: _isInteractive ? _handleTapCancel : null,
        child: reducedMotion
            ? widget.child
            : AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: widget.child,
              ),
      ),
    );
    final semantics = Semantics(
      button: _hasAction,
      enabled: _isInteractive,
      child: child,
    );
    return widget.tooltip == null
        ? semantics
        : Tooltip(message: widget.tooltip!, child: semantics);
  }

  @override
  Widget build(BuildContext context) => _materialChild(context);
}

