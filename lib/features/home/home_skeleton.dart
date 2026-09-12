import 'package:flutter/material.dart';

/// Skeleton loading state for HomeScreen matching Paper canvas artboard CL-1.
class HomeSkeletonScreen extends StatefulWidget {
  const HomeSkeletonScreen({super.key});

  @override
  State<HomeSkeletonScreen> createState() => _HomeSkeletonScreenState();
}

class _HomeSkeletonScreenState extends State<HomeSkeletonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    double? width,
    required double height,
    double radius = 8,
    Color color = const Color(0xFFE2E8F0),
  }) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Opacity(
          opacity: _shimmer.value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // User Header Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _box(width: 44, height: 44, radius: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(width: 80, height: 12, radius: 6),
                          const SizedBox(height: 6),
                          _box(width: 140, height: 16, radius: 8),
                        ],
                      ),
                    ],
                  ),
                  _box(width: 40, height: 40, radius: 20),
                ],
              ),
              const SizedBox(height: 14),

              // Weekly Progress Bento Card Skeleton
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(width: 85, height: 22, radius: 11),
                          const SizedBox(height: 10),
                          _box(width: 150, height: 16, radius: 8),
                          const SizedBox(height: 6),
                          _box(width: 110, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    _box(width: 76, height: 76, radius: 38),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Unit Status Skeleton Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(width: 130, height: 16, radius: 8),
                      const SizedBox(height: 4),
                      _box(width: 90, height: 11, radius: 5),
                    ],
                  ),
                  _box(width: 60, height: 22, radius: 11),
                ],
              ),
              const SizedBox(height: 12),

              // 3 Unit Cards Skeleton Row
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      padding: const EdgeInsets.all(12),
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _box(width: 28, height: 12, radius: 4),
                              _box(width: 24, height: 12, radius: 6),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _box(width: 32, height: 20, radius: 4),
                              const SizedBox(height: 4),
                              _box(width: 55, height: 10, radius: 4),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Upcoming Orders Skeleton Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _box(width: 140, height: 16, radius: 8),
                      const SizedBox(width: 8),
                      _box(width: 22, height: 18, radius: 9),
                    ],
                  ),
                  _box(width: 60, height: 14, radius: 6),
                ],
              ),
              const SizedBox(height: 12),

              // 2 Order Cards Skeleton List
              Column(
                children: List.generate(2, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _box(width: 120, height: 14, radius: 6),
                            _box(width: 80, height: 20, radius: 10),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _box(width: double.infinity, height: 14, radius: 6),
                        const SizedBox(height: 10),
                        _box(width: 140, height: 12, radius: 6),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
