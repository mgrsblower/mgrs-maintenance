import 'package:flutter/material.dart';
import 'pressable.dart';

/// Clean, elevated operational bottom navigation dock for MGRS Maintenance.
/// Features high-contrast labels, active cobalt state, and a prominent cobalt hero scanner button.
class AppBottomNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      child: Row(
        children: [
          // Elevated Capsule Nav Bar
          Expanded(
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTab(
                    index: 0,
                    label: 'Beranda',
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                  ),
                  _buildTab(
                    index: 1,
                    label: 'Aset',
                    activeIcon: Icons.inventory_2_rounded,
                    inactiveIcon: Icons.inventory_2_outlined,
                  ),
                  _buildTab(
                    index: 2,
                    label: 'Servis',
                    activeIcon: Icons.build_rounded,
                    inactiveIcon: Icons.build_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Floating QR Scanner Button (MGRS Cobalt Hero Action)
          PressableScale(
            onTap: onOpenScanner,
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

  Widget _buildTab({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isActive = currentIndex == index;

    if (isActive) {
      return Expanded(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(activeIcon, size: 20, color: const Color(0xFF147CC1)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF147CC1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: PressableScale(
        onTap: () => onNavigateToTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(inactiveIcon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
