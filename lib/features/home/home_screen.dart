import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../schedule/order_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.gateway,
    required this.user,
    required this.onNavigateToTab,
    required this.onOpenScanner,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildUserHeader(context),
                      const SizedBox(height: 14),
                      _buildWeeklyProgressBento(context),
                      const SizedBox(height: 20),
                      _buildUnitStatusSection(context),
                      const SizedBox(height: 20),
                      _buildUpcomingOrdersSection(context),
                      const SizedBox(height: 90), // Spacing for floating navbar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPaperBottomNav(context),
    );
  }

  // 1. User Header: Avatar "SR" + "Selamat Pagi! Salman Alfarras" + Bell Icon
  Widget _buildUserHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'SR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Pagi!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role == 'Admin' ? 'Admin MGRS' : 'Salman Alfarras',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF334155),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Bento Card: Lime #CEF284 + "Pengingat!" chip + "Pengecekan Unit Berkala" + Circular Progress "6 Hari Lagi"
  Widget _buildWeeklyProgressBento(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEF284),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Color(0xFF22380E)),
                      SizedBox(width: 5),
                      Text(
                        'Pengingat!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF22380E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pengecekan Unit\nBerkala',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A330E),
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          // Circular Progress Widget
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(86, 86),
                  painter: _CircularCountdownPainter(),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '6',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B350F),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hari Lagi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF527032),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Status Unit Blower (Total 24 mesin aktif dipantau + Live Data badge + 3 gradient cards)
  Widget _buildUnitStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Unit Blower',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Total 24 mesin aktif dipantau',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                  SizedBox(width: 5),
                  Text(
                    'Live Data',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 3 Gradient Status Cards
        Row(
          children: [
            // Card 1: 19 Beroperasi (Green Gradient)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.check_rounded,
                percentage: '79%',
                count: '19',
                title: 'Beroperasi',
                subtitle: 'Kondisi prima',
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                shadowColor: const Color(0x4010B981),
                subtitleColor: const Color(0xFFD1FAE5),
              ),
            ),
            const SizedBox(width: 10),
            // Card 2: 3 Perlu Servis (Amber Gradient)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.build_rounded,
                percentage: '13%',
                count: '3',
                title: 'Perlu Servis',
                subtitle: 'Jadwal dekat',
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                shadowColor: const Color(0x40D97706),
                subtitleColor: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 10),
            // Card 3: 2 Kendala (Rose Gradient)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.warning_amber_rounded,
                percentage: '8%',
                count: '2',
                title: 'Kendala',
                subtitle: 'Cek fisik',
                gradientColors: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                shadowColor: const Color(0x40E11D48),
                subtitleColor: const Color(0xFFFFE4E6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientStatusCard({
    required IconData icon,
    required String percentage,
    required String count,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color shadowColor,
    required Color subtitleColor,
  }) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentage,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Orderan Mendatang (Section title + count badge "3" + "Lihat Semua" + 2 Order Cards)
  Widget _buildUpcomingOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Orderan Mendatang',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => onNavigateToTab(2),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Order Card 1
        _buildOrderCard(
          context,
          badgeColor: const Color(0xFFEF4444),
          orderCode: 'ORD-2026-088',
          units: '• 4 Unit',
          dateText: 'Besok, 26 Jul 2029',
          dateBgColor: const Color(0xFFFEF2F2),
          dateTextColor: const Color(0xFFDC2626),
          title: 'Pemasangan Panggung Event Pertamina',
          venue: 'JCC Senayan, Hall B - Jakarta',
        ),
        const SizedBox(height: 10),
        // Order Card 2
        _buildOrderCard(
          context,
          badgeColor: const Color(0xFF3B82F6),
          orderCode: 'ORD-2026-092',
          units: '• 2 Unit',
          dateText: 'Jumat, 27 Jul 2029',
          dateBgColor: const Color(0xFFF1F5F9),
          dateTextColor: const Color(0xFF475569),
          title: 'Instalasi Outdoor Festival Musik',
          venue: 'Lapangan Brigif, Cimahi',
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context, {
    required Color badgeColor,
    required String orderCode,
    required String units,
    required String dateText,
    required Color dateBgColor,
    required Color dateTextColor,
    required String title,
    required String venue,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const OrderDetailScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    orderCode,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    units,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dateBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dateTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      venue,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // 5. Paper Glassmorphic Floating Bottom Bar: Pill Nav (Beranda, Aset, Servis) + Separate Floating QR Button
  Widget _buildPaperBottomNav(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      child: Row(
        children: [
          // Glassmorphic Capsule Nav Bar
          Expanded(
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xCEE7E7E7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xC7FFFFFF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tab Beranda (Active Pill)
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x9EA6A6A6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_filled, size: 22, color: Colors.black),
                          SizedBox(height: 2),
                          Text(
                            'Beranda',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab Aset
                  Expanded(
                    child: InkWell(
                      onTap: () => onNavigateToTab(1),
                      borderRadius: BorderRadius.circular(24),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_in_ar_outlined, size: 20, color: Colors.black),
                          SizedBox(height: 2),
                          Text(
                            'Aset',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab Servis
                  Expanded(
                    child: InkWell(
                      onTap: () => onNavigateToTab(2),
                      borderRadius: BorderRadius.circular(24),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_rounded, size: 20, color: Colors.black),
                          SizedBox(height: 2),
                          Text(
                            'Servis',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Separate Floating QR Scanner Button
          GestureDetector(
            onTap: onOpenScanner,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xC7E7E7E7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xC7FFFFFF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for countdown circular ring in Bento Card
class _CircularCountdownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background track ring
    final trackPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, 35, trackPaint);

    // Inner filled circle with opacity
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 25, innerPaint);

    // Inner border stroke
    final innerStroke = Paint()
      ..color = const Color(0xFFCEF284)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 25, innerStroke);

    // Progress Arc #78C423
    final progressPaint = Paint()
      ..color = const Color(0xFF78C423)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Draw arc ~ 270 degrees
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 35),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
