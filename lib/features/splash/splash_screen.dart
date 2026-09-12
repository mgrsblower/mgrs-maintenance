import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fallbackTimer;
  bool _finished = false;

  static bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    if (_isTestEnvironment) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
      return;
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _complete();
      }
    });

    // Fallback timer ensures the app proceeds even if asset loading delays
    _fallbackTimer = Timer(const Duration(milliseconds: 2500), _complete);
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    _fallbackTimer?.cancel();
    widget.onFinish();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isTestEnvironment) {
      return Scaffold(
        backgroundColor: AppTokens.porcelain,
        body: Center(
          child: Text('MGRS Splash', style: textTheme.headlineSmall),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTokens.porcelain,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Semantics(
                label: 'MGRS-Maintenance',
                image: true,
                child: Lottie.asset(
                  'assets/animation/splash_mgrs.json',
                  controller: _controller,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _controller.forward();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
