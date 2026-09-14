import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_button.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import '../../shared/bottom_nav_bar.dart';
import '../schedule/order_detail_screen.dart';
import '../schedule/order_model.dart';
import '../schedule/upcoming_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.gateway,
    required this.user,
    required this.onNavigateToTab,
    required this.onOpenScanner,
    this.adminMode,
    this.onSwitchAdminMode,
    this.showBottomNav = true,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenScanner;
  final AdminAppMode? adminMode;
  final ValueChanged<AdminAppMode>? onSwitchAdminMode;
  final bool showBottomNav;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _operatingCount = 0;
  int _serviceCount = 0;
  int _problemCount = 0;
  int _totalMonitored = 0;
  String _countdownDays = '0';
  List<OrderanSewa> _upcomingOrders = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final list = await widget.gateway.fetchComponents(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      int ok = 0;
      int service = 0;
      int problem = 0;
      for (final item in list) {
        final condition = (item['kondisi'] ?? item['condition'] ?? 'OK')
            .toString();
        if (condition == 'OK') {
          ok++;
        } else if (condition == 'Service' || condition == 'Rusak Ringan') {
          service++;
        } else {
          problem++;
        }
      }

      String countdown = '0';
      try {
        final tasks = await widget.gateway.fetchTasksSummary(
          forceRefresh: forceRefresh,
        );
        final period = tasks['period'];
        if (period is Map) {
          final opensAt = DateTime.tryParse(
            period['opensAt']?.toString() ?? '',
          );
          if (opensAt != null) {
            final difference = opensAt.difference(DateTime.now()).inDays;
            countdown = difference > 0 ? '$difference' : '0';
          }
        }
      } catch (_) {}

      List<OrderanSewa> upcoming = [];
      try {
        final all = await widget.gateway.fetchUpcomingOrders(
          limit: 20,
          forceRefresh: forceRefresh,
        );
        upcoming = all.where((order) => order.isUpcoming).take(5).toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _operatingCount = ok;
        _serviceCount = service;
        _problemCount = problem;
        _totalMonitored = list.length;
        _countdownDays = countdown;
        _upcomingOrders = upcoming;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MgrsColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadMetrics(forceRefresh: true),
          color: MgrsColors.operational,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MgrsSpacing.lg,
                  MgrsSpacing.md,
                  MgrsSpacing.lg,
                  110,
                ),
                sliver: SliverList.list(
                  children: [
                    _buildUserHeader(context),
                    const SizedBox(height: MgrsSpacing.lg),
                    _buildReminder(),
                    const SizedBox(height: MgrsSpacing.xl),
                    _buildUnitStatusSection(),
                    const SizedBox(height: MgrsSpacing.xl),
                    _buildUpcomingOrdersSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNavBar(
              currentIndex: 0,
              onNavigateToTab: widget.onNavigateToTab,
              onOpenScanner: widget.onOpenScanner,
            )
          : null,
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Buka profil ${widget.user.displayName}',
            child: InkWell(
              onTap: () => _showUserProfileBottomSheet(context),
              borderRadius: BorderRadius.circular(MgrsRadii.compact),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.xs),
                child: Row(
                  children: [
                    _avatar(widget.user.initials, 48),
                    const SizedBox(width: MgrsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MgrsColors.muted,
                            ),
                          ),
                          const SizedBox(height: MgrsSpacing.xs),
                          Text(
                            widget.user.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: MgrsColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more, color: MgrsColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: MgrsColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        maxLines: 1,
        style: TextStyle(
          fontSize: size * .34,
          fontWeight: FontWeight.w600,
          color: MgrsColors.surface,
        ),
      ),
    );
  }

  void _showUserProfileBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MgrsColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MgrsRadii.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              MgrsSpacing.lg,
              MgrsSpacing.md,
              MgrsSpacing.lg,
              MgrsSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MgrsColors.line,
                      borderRadius: BorderRadius.circular(MgrsRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: MgrsSpacing.md),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profil Pengguna',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MgrsColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup profil',
                      constraints: const BoxConstraints.tightFor(
                        width: MgrsSizes.minTouch,
                        height: MgrsSizes.minTouch,
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: MgrsSpacing.base),
                Container(
                  padding: const EdgeInsets.all(MgrsSpacing.base),
                  decoration: BoxDecoration(
                    color: MgrsColors.canvas,
                    borderRadius: BorderRadius.circular(MgrsRadii.card),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatar(widget.user.initials, 52),
                      const SizedBox(width: MgrsSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: MgrsColors.ink,
                              ),
                            ),
                            const SizedBox(height: MgrsSpacing.sm),
                            MgrsStatusBadge(
                              widget.user.role,
                              tone: MgrsStatusTone.success,
                            ),
                            if (widget.user.username != null) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              Text(
                                '@${widget.user.username}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: MgrsColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MgrsSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: MgrsColors.success,
                    ),
                    const SizedBox(width: MgrsSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.user.isAdmin
                            ? 'Sistem MGRS, akun administrator aktif'
                            : 'Sistem MGRS terhubung',
                        style: const TextStyle(
                          color: MgrsColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.user.isAdmin &&
                    widget.onSwitchAdminMode != null) ...[
                  const SizedBox(height: MgrsSpacing.xl),
                  const Text(
                    'Mode tampilan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MgrsColors.ink,
                    ),
                  ),
                  const SizedBox(height: MgrsSpacing.xs),
                  const Text(
                    'Pilih peran operasional yang ingin diakses.',
                    style: TextStyle(color: MgrsColors.muted),
                  ),
                  const SizedBox(height: MgrsSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final vertical =
                          constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.5;
                      final choices = [
                        _modeButton(
                          sheetContext,
                          label: 'Mode PIC',
                          icon: Icons.event_note_outlined,
                          mode: AdminAppMode.pic,
                        ),
                        _modeButton(
                          sheetContext,
                          label: 'Mode Servis',
                          icon: Icons.build_outlined,
                          mode: AdminAppMode.service,
                        ),
                      ];
                      return vertical
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                choices.first,
                                const SizedBox(height: MgrsSpacing.sm),
                                choices.last,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: choices.first),
                                const SizedBox(width: MgrsSpacing.sm),
                                Expanded(child: choices.last),
                              ],
                            );
                    },
                  ),
                ],
                const SizedBox(height: MgrsSpacing.xl),
                MgrsButton.destructive(
                  label: 'Keluar dari akun',
                  icon: Icons.logout,
                  onPressed: () => _confirmLogout(context, sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(
    BuildContext sheetContext, {
    required String label,
    required IconData icon,
    required AdminAppMode mode,
  }) {
    final selected = widget.adminMode == mode;
    return SizedBox(
      height: MgrsSizes.minTouch,
      child: selected
          ? FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                widget.onSwitchAdminMode!(mode);
              },
              icon: Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: MgrsColors.ink,
                foregroundColor: MgrsColors.surface,
              ),
            )
          : OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                widget.onSwitchAdminMode!(mode);
              },
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: MgrsColors.ink,
                side: const BorderSide(color: MgrsColors.line),
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext screenContext, BuildContext sheetContext) {
    showDialog<void>(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MgrsRadii.card),
        ),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Sesi kerja di perangkat ini akan berakhir. Anda perlu masuk kembali untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              Navigator.of(sheetContext).pop();
              await widget.gateway.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: MgrsColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder() {
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.lg),
      decoration: BoxDecoration(
        color: MgrsColors.warningSoft,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: MgrsColors.warning,
            size: 28,
          ),
          const SizedBox(width: MgrsSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengecekan unit berkala',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MgrsColors.ink,
                  ),
                ),
                SizedBox(height: MgrsSpacing.xs),
                Text(
                  'Waktu menuju periode pemeriksaan berikutnya',
                  style: TextStyle(color: MgrsColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: MgrsSpacing.md),
          Semantics(
            label: '$_countdownDays hari lagi',
            child: Column(
              children: [
                Text(
                  _countdownDays,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: MgrsColors.warning,
                  ),
                ),
                const Text(
                  'hari lagi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MgrsColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Status Unit Blower',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MgrsColors.ink,
          ),
        ),
        const SizedBox(height: MgrsSpacing.xs),
        Text(
          _loading
              ? 'Memuat kondisi unit'
              : _loadFailed
              ? 'Data unit belum dapat dimuat'
              : _totalMonitored == 0
              ? 'Belum ada unit terdata'
              : '$_totalMonitored unit dipantau',
          style: const TextStyle(color: MgrsColors.muted),
        ),
        const SizedBox(height: MgrsSpacing.md),
        if (_loading)
          const MgrsStateView.loading(title: 'Memuat status unit...')
        else if (_loadFailed)
          MgrsStateView.error(
            title: 'Status unit belum tersedia',
            message: 'Periksa koneksi, lalu muat data terbaru.',
            actionLabel: 'Muat data terbaru',
            onAction: () => _loadMetrics(forceRefresh: true),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final columns = constraints.maxWidth >= 520 && textScale <= 1.5
                  ? 3
                  : constraints.maxWidth >= 330 && textScale <= 1.25
                  ? 3
                  : 1;
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - MgrsSpacing.md * (columns - 1)) /
                        columns;
              return Wrap(
                spacing: MgrsSpacing.md,
                runSpacing: MgrsSpacing.md,
                children: [
                  _statusCard(
                    width: width,
                    icon: Icons.check_circle_outline,
                    count: _operatingCount,
                    title: 'Beroperasi',
                    tone: MgrsStatusTone.success,
                  ),
                  _statusCard(
                    width: width,
                    icon: Icons.build_outlined,
                    count: _serviceCount,
                    title: 'Perlu Servis',
                    tone: MgrsStatusTone.warning,
                  ),
                  _statusCard(
                    width: width,
                    icon: Icons.error_outline,
                    count: _problemCount,
                    title: 'Kendala',
                    tone: MgrsStatusTone.danger,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _statusCard({
    required double width,
    required IconData icon,
    required int count,
    required String title,
    required MgrsStatusTone tone,
  }) {
    final percentage = _totalMonitored == 0
        ? 0
        : ((count / _totalMonitored) * 100).round();
    final colors = switch (tone) {
      MgrsStatusTone.success => (MgrsColors.success, MgrsColors.successSoft),
      MgrsStatusTone.warning => (MgrsColors.warning, MgrsColors.warningSoft),
      MgrsStatusTone.danger => (MgrsColors.danger, MgrsColors.dangerSoft),
    };
    return Semantics(
      label: '$title, $count unit, $percentage persen',
      child: Container(
        width: width,
        padding: const EdgeInsets.all(MgrsSpacing.base),
        decoration: BoxDecoration(
          color: colors.$2,
          borderRadius: BorderRadius.circular(MgrsRadii.compact),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.$1),
            const SizedBox(width: MgrsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.$1,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MgrsColors.ink,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: MgrsColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Orderan Mendatang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MgrsColors.ink,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => UpcomingOrdersScreen(
                    gateway: widget.gateway,
                    user: widget.user,
                  ),
                ),
              ),
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        const SizedBox(height: MgrsSpacing.md),
        if (_loading)
          const MgrsStateView.loading(title: 'Memuat orderan...')
        else if (_upcomingOrders.isEmpty)
          MgrsStateView.empty(
            title: 'Belum ada orderan mendatang',
            message: 'Orderan baru akan muncul di bagian ini.',
            actionLabel: 'Lihat semua orderan',
            onAction: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => UpcomingOrdersScreen(
                  gateway: widget.gateway,
                  user: widget.user,
                ),
              ),
            ),
          )
        else
          ..._upcomingOrders
              .take(3)
              .map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: MgrsSpacing.md),
                  child: _buildOrderCard(context, order),
                ),
              ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final hasMaps =
        order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
    final hasWhatsApp = order.cleanWhatsapp.isNotEmpty;
    final status = order.isPast
        ? order.isCompletedOrCancelled
              ? (order.statusOrderan ?? 'Selesai')
              : 'Selesai / Lewat'
        : (order.statusOrderan?.isNotEmpty ?? false)
        ? order.statusOrderan!
        : 'Terjadwal';

    return Semantics(
      button: true,
      label: '${order.displayCode}, ${order.namaEvent}, $status',
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              order: order,
              gateway: widget.gateway,
              user: widget.user,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        child: Ink(
          padding: const EdgeInsets.all(MgrsSpacing.base),
          decoration: BoxDecoration(
            color: MgrsColors.surface,
            borderRadius: BorderRadius.circular(MgrsRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: MgrsSpacing.sm,
                runSpacing: MgrsSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    order.displayCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MgrsColors.ink,
                    ),
                  ),
                  MgrsStatusBadge(
                    status,
                    tone: order.isPast
                        ? MgrsStatusTone.warning
                        : MgrsStatusTone.success,
                  ),
                ],
              ),
              const SizedBox(height: MgrsSpacing.md),
              Text(
                order.namaEvent,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MgrsColors.ink,
                ),
              ),
              const SizedBox(height: MgrsSpacing.xs),
              Text(
                '${order.jumlahUnit} unit · ${order.durasiSewaText}',
                style: const TextStyle(color: MgrsColors.muted),
              ),
              if (order.namaClient?.isNotEmpty ?? false) ...[
                const SizedBox(height: MgrsSpacing.sm),
                Text(
                  'Klien: ${order.namaClient}',
                  style: const TextStyle(color: MgrsColors.ink),
                ),
              ],
              if (order.alamat?.isNotEmpty ?? false) ...[
                const SizedBox(height: MgrsSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: MgrsColors.muted,
                    ),
                    const SizedBox(width: MgrsSpacing.xs),
                    Expanded(
                      child: Text(
                        order.alamat!,
                        style: const TextStyle(
                          color: MgrsColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: MgrsSpacing.md),
              const Divider(height: 1, color: MgrsColors.line),
              const SizedBox(height: MgrsSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final actions = <Widget>[
                    if (hasMaps)
                      IconButton(
                        tooltip: 'Buka lokasi di peta',
                        onPressed: order.launchMaps,
                        icon: const Icon(Icons.near_me_outlined),
                        color: MgrsColors.operational,
                      ),
                    if (hasWhatsApp)
                      IconButton(
                        tooltip: 'Hubungi klien melalui WhatsApp',
                        onPressed: order.launchWhatsApp,
                        icon: const Icon(Icons.chat_outlined),
                        color: MgrsColors.success,
                      ),
                  ];
                  return Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: MgrsColors.muted,
                      ),
                      const SizedBox(width: MgrsSpacing.sm),
                      Expanded(
                        child: Text(
                          order.dayDateYear,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: MgrsColors.ink,
                          ),
                        ),
                      ),
                      ...actions,
                      if (actions.isEmpty)
                        const Icon(
                          Icons.chevron_right,
                          color: MgrsColors.muted,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
