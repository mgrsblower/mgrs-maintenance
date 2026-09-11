import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import '../schedule/order_detail_screen.dart';
import '../schedule/order_model.dart';

class PicHomeScreen extends StatefulWidget {
  const PicHomeScreen({
    super.key,
    required this.gateway,
    required this.user,
    required this.onOpenOrdersTab,
    required this.onOpenInvoicesTab,
    this.adminMode,
    this.onSwitchAdminMode,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final VoidCallback onOpenOrdersTab;
  final VoidCallback onOpenInvoicesTab;
  final AdminAppMode? adminMode;
  final ValueChanged<AdminAppMode>? onSwitchAdminMode;

  @override
  State<PicHomeScreen> createState() => _PicHomeScreenState();
}

class _PicHomeScreenState extends State<PicHomeScreen> {
  bool _isLoading = true;
  String? _error;
  List<OrderanSewa> _allOrders = [];
  List<OrderanSewa> _upcomingOrders = [];
  List<OrderanSewa> _pastOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allOrders = await widget.gateway
          .fetchUpcomingOrders(limit: 50, forceRefresh: forceRefresh);

      if (!mounted) return;

      setState(() {
        _allOrders = allOrders;
        _upcomingOrders = allOrders.where((o) => o.isUpcoming).toList();
        _pastOrders = allOrders.where((o) => o.isPast).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = failureMessage(e);
        _isLoading = false;
      });
    }
  }

  int get _thisMonthOrdersCount {
    try {
      final list = _allOrders;
      if (list.isEmpty) return 0;
      final now = DateTime.now();
      var count = 0;
      for (var i = 0; i < list.length; i++) {
        final dt = list[i].tanggalPemasangan;
        if (dt != null && dt.year == now.year && dt.month == now.month) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  int get _todayOrdersCount {
    try {
      final list = _upcomingOrders;
      if (list.isEmpty) return 0;
      final now = DateTime.now();
      var count = 0;
      for (var i = 0; i < list.length; i++) {
        final dt = list[i].tanggalPemasangan;
        if (dt != null &&
            dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  int get _totalOrdersCount {
    try {
      return _allOrders.length;
    } catch (_) {
      return 0;
    }
  }

  int get _upcomingCount {
    try {
      return _upcomingOrders.length;
    } catch (_) {
      return 0;
    }
  }

  int get _pastCount {
    try {
      return _pastOrders.length;
    } catch (_) {
      return 0;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi!';
    if (hour < 15) return 'Selamat Siang!';
    if (hour < 18) return 'Selamat Sore!';
    return 'Selamat Malam!';
  }

  static String _formatMonthName(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showUserProfileBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // User Info Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C3E66),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1C3E66)
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.user.initials,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    widget.user.role,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                if (widget.user.username != null) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '@${widget.user.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Status Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        widget.user.isAdmin
                            ? 'Sistem MGRS • Akun Administrator'
                            : 'Sistem MGRS • Terhubung (Mode PIC)',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mode Tampilan Operasional (Admin Only)
                if (widget.user.isAdmin && widget.onSwitchAdminMode != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 16, color: Color(0xFF0F172A)),
                            SizedBox(width: 6),
                            Text(
                              'Mode Tampilan (Khusus Admin)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pilih peran tampilan operasional yang ingin Anda akses:',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 38,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PressableScale(
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    widget.onSwitchAdminMode!(AdminAppMode.pic);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.adminMode == AdminAppMode.pic
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: widget.adminMode == AdminAppMode.pic
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x10000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_note_rounded,
                                          size: 14,
                                          color: widget.adminMode == AdminAppMode.pic
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Mode PIC',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11.5,
                                            fontWeight: widget.adminMode == AdminAppMode.pic
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: widget.adminMode == AdminAppMode.pic
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: PressableScale(
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    widget.onSwitchAdminMode!(AdminAppMode.service);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.adminMode == AdminAppMode.service
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: widget.adminMode == AdminAppMode.service
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x10000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.build_rounded,
                                          size: 14,
                                          color: widget.adminMode == AdminAppMode.service
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Mode Servis',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11.5,
                                            fontWeight: widget.adminMode == AdminAppMode.service
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: widget.adminMode == AdminAppMode.service
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Logout Button
                PressableScale(
                  onTap: () => _confirmLogout(context, sheetContext),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext screenContext, BuildContext sheetContext) {
    showDialog<void>(
      context: screenContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun MGRS?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              Navigator.of(sheetContext).pop();
              await widget.gateway.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: _buildUserHeader(context),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF147CC1)),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Color(0xFFDC2626)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _loadData(forceRefresh: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF147CC1),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCreateOrderBento(context),
                        const SizedBox(height: 20),
                        _buildSummaryStatusSection(context),
                        const SizedBox(height: 24),
                        _buildUpcomingOrdersHeader(context),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildUpcomingOrdersList(context),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 110), // Spacing for floating navbar
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 1. User Header: Avatar initials + "Selamat Pagi! Name" + Bell Icon (matching HomeScreen)
  Widget _buildUserHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: PressableScale(
            onTap: () => _showUserProfileBottomSheet(context),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.user.initials,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        PressableScale(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF334155),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Bento Hero Card: Total orderan bulan ini dengan Progress Ring (identik dengan HomeScreen)
  Widget _buildCreateOrderBento(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEF284),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBCE66E), width: 1.2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: Color(0xFF22380E)),
                      const SizedBox(width: 5),
                      Text(
                        _formatMonthName(DateTime.now()),
                        style: const TextStyle(
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
                  'Total Orderan\nBulan Ini',
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
          // Circular Progress Ring Widget identik dengan HomeScreen
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(86, 86),
                  painter: _CircularProgressRingPainter(),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_thisMonthOrdersCount',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B350F),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Orderan',
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

  // 3. Status Section: 3 Ringkasan Order (Total Order, Akan Datang, Selesai)
  Widget _buildSummaryStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Orderan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _totalOrdersCount == 0 && !_isLoading
                        ? 'Belum ada data orderan'
                        : 'Total $_totalOrdersCount orderan tercatat di sistem',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                    'Data Terkini',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
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
        // 3 Vibrant Solid Status Cards: Total Order, Akan Datang, Selesai (style identik HomeScreen)
        Row(
          children: [
            // Card 1: Total Order (Blue Solid)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.assignment_outlined,
                percentage: '100%',
                count: '$_totalOrdersCount',
                title: 'Total Order',
                subtitle: 'Semua riwayat',
                solidColor: const Color(0xFF147CC1),
                onTap: widget.onOpenOrdersTab,
              ),
            ),
            const SizedBox(width: 10),
            // Card 2: Akan Datang (Amber Solid)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.event_available_rounded,
                percentage: _totalOrdersCount > 0
                    ? '${((_upcomingCount / _totalOrdersCount) * 100).round()}%'
                    : '0%',
                count: '$_upcomingCount',
                title: 'Akan Datang',
                subtitle: '$_todayOrdersCount hari ini',
                solidColor: const Color(0xFFD97706),
                onTap: widget.onOpenOrdersTab,
              ),
            ),
            const SizedBox(width: 10),
            // Card 3: Selesai (Emerald Solid)
            Expanded(
              child: _buildGradientStatusCard(
                icon: Icons.check_circle_outline_rounded,
                percentage: _totalOrdersCount > 0
                    ? '${((_pastCount / _totalOrdersCount) * 100).round()}%'
                    : '0%',
                count: '$_pastCount',
                title: 'Selesai',
                subtitle: 'Event beres',
                solidColor: const Color(0xFF059669),
                onTap: widget.onOpenOrdersTab,
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
    required Color solidColor,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: solidColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: solidColor.withValues(alpha: 0.28),
              blurRadius: 10,
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Orderan Mendatang Header (matching HomeScreen)
  Widget _buildUpcomingOrdersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Flexible(
                child: Text(
                  'Orderan Mendatang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_upcomingCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onOpenOrdersTab,
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
    );
  }

  // 5. Order Cards List (matching HomeScreen._buildOrderCard)
  Widget _buildUpcomingOrdersList(BuildContext context) {
    final list = _upcomingOrders;
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.event_available_rounded,
                    size: 32, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'Tidak ada orderan mendatang saat ini',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Jadwal pemasangan diperbarui otomatis saat ada orderan baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayList = list.take(4).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = displayList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOrderCard(context, order),
            );
          },
          childCount: displayList.length,
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final hasMaps =
        order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
    final hasWa = order.cleanWhatsapp.isNotEmpty;

    final isPast = order.isPast;
    final String statusText;
    final Color statusBg;
    final Color statusBorder;
    final Color statusColor;
    final Color dotColor;

    if (order.isCancelled) {
      statusText = 'Dibatalkan';
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusColor = const Color(0xFFDC2626);
      dotColor = const Color(0xFFEF4444);
    } else if (isPast) {
      statusText = order.isCompletedOrCancelled
          ? (order.statusOrderan ?? 'Selesai')
          : 'Selesai / Lewat';
      statusBg = const Color(0xFFF1F5F9);
      statusBorder = const Color(0xFFCBD5E1);
      statusColor = const Color(0xFF475569);
      dotColor = const Color(0xFF94A3B8);
    } else {
      statusText =
          (order.statusOrderan != null && order.statusOrderan!.isNotEmpty)
              ? order.statusOrderan!
              : 'Terjadwal';
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusColor = const Color(0xFF059669);
      dotColor = const Color(0xFF10B981);
    }

    return PressableScale(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              order: order,
              gateway: widget.gateway,
              user: widget.user,
            ),
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
            // 1. Header: [ ● ORD-XXX • 10 Unit (1 Hari) ]  ...  [ Terjadwal ]
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          order.displayCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${order.jumlahUnit} Unit',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Text(
                        ' (${order.durasiSewaText})',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. Body: Nama Event (Bold)
            Text(
              order.namaEvent,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),

            // Detail Klien jika ada
            if (order.namaClient != null && order.namaClient!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'Klien: ${order.namaClient}${order.nomorWhatsapp != null && order.nomorWhatsapp!.isNotEmpty ? ' • ${order.nomorWhatsapp}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            // Alamat Venue
            if (order.alamat != null && order.alamat!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.alamat!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // 3. Footer: [ Kamis, 10 Sep 2026 ]  ...  [ Maps ] [ WA ]
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
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.dayDateYear,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMaps)
                        PressableScale(
                          onTap: () => order.launchMaps(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.near_me_rounded,
                                    size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  'Maps',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (hasMaps && hasWa) const SizedBox(width: 6),
                      if (hasWa)
                        PressableScale(
                          onTap: () => order.launchWhatsApp(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_rounded,
                                    size: 12, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'WA',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!hasMaps && !hasWa)
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressRingPainter extends CustomPainter {
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
