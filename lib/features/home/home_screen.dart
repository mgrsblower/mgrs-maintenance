import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final list =
          await widget.gateway.fetchComponents(forceRefresh: forceRefresh);
      if (!mounted) return;
      int ok = 0;
      int service = 0;
      int problem = 0;
      for (final item in list) {
        final cond = (item['kondisi'] ?? item['condition'] ?? 'OK').toString();
        if (cond == 'OK') {
          ok++;
        } else if (cond == 'Service' || cond == 'Rusak Ringan') {
          service++;
        } else {
          problem++;
        }
      }

      String countdown = '0';
      try {
        final tasks = await widget.gateway
            .fetchTasksSummary(forceRefresh: forceRefresh);
        if (tasks.isNotEmpty) {
          final period = tasks['period'];
          if (period is Map) {
            final opensAtStr = period['opensAt']?.toString();
            if (opensAtStr != null) {
              final opensAt = DateTime.tryParse(opensAtStr);
              if (opensAt != null) {
                final diff = opensAt.difference(DateTime.now()).inDays;
                countdown = diff > 0 ? '$diff' : '0';
              }
            }
          }
        }
      } catch (_) {}

      List<OrderanSewa> upcoming = [];
      try {
        final all = await widget.gateway
            .fetchUpcomingOrders(limit: 20, forceRefresh: forceRefresh);
        upcoming = all.where((o) => o.isUpcoming).take(5).toList();
      } catch (_) {}

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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadMetrics(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTokens.space16),
                    _buildUserHeader(context),
                    const SizedBox(height: AppTokens.space16),
                    _buildWeeklyProgressBento(context),
                    const SizedBox(height: AppTokens.space24),
                    _buildUnitStatusSection(context),
                    const SizedBox(height: AppTokens.space24),
                    _buildUpcomingOrdersSection(context),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showUserProfileBottomSheet(context),
            borderRadius: BorderRadius.circular(AppTokens.controlRadius),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: AppTokens.minTouchTarget),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                    child: Text(
                      widget.user.initials,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Selamat Pagi!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18),
                          ],
                        ),
                        Text(
                          widget.user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        IconButton.outlined(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifikasi',
        ),
      ],
    );
  }

  void _showUserProfileBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final operational = theme.extension<OperationalColors>()!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space24,
              0,
              AppTokens.space24,
              AppTokens.space32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Profil Pengguna',
                          style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                          child: Text(
                            widget.user.initials,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.displayName,
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: AppTokens.space8),
                              Wrap(
                                spacing: AppTokens.space8,
                                runSpacing: AppTokens.space4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Semantics(
                                    label:
                                        'Label peran inventaris: ${widget.user.role}',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTokens.space8,
                                        vertical: AppTokens.space4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.secondaryContainer,
                                        borderRadius: BorderRadius.circular(
                                            AppTokens.badgeRadius),
                                      ),
                                      child: Text(
                                        widget.user.role,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: colors.onSecondaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (widget.user.username != null)
                                    Text(
                                      '@${widget.user.username}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Container(
                  padding: const EdgeInsets.all(AppTokens.space12),
                  decoration: BoxDecoration(
                    color: operational.success,
                    borderRadius:
                        BorderRadius.circular(AppTokens.controlRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: operational.onSuccess),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          widget.user.isAdmin
                              ? 'Sistem MGRS • Akun Administrator'
                              : 'Sistem MGRS • Terhubung',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: operational.onSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.user.isAdmin &&
                    widget.onSwitchAdminMode != null) ...[
                  const SizedBox(height: AppTokens.space16),
                  Text(
                    'Mode Tampilan (Khusus Admin)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Pilih peran tampilan operasional yang ingin Anda akses:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  SegmentedButton<AdminAppMode>(
                    segments: const [
                      ButtonSegment(
                        value: AdminAppMode.pic,
                        icon: Icon(Icons.event_note_rounded),
                        label: Text('Mode PIC'),
                      ),
                      ButtonSegment(
                        value: AdminAppMode.service,
                        icon: Icon(Icons.build_rounded),
                        label: Text('Mode Servis'),
                      ),
                    ],
                    selected: {widget.adminMode ?? AdminAppMode.service},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      Navigator.of(sheetContext).pop();
                      widget.onSwitchAdminMode!(selection.first);
                    },
                  ),
                ],
                const SizedBox(height: AppTokens.space24),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, sheetContext),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
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
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun MGRS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              Navigator.of(sheetContext).pop();
              await widget.gateway.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressBento(BuildContext context) {
    final theme = Theme.of(context);
    final operational = theme.extension<OperationalColors>()!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Pengingat inventaris',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space8,
                        vertical: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: operational.warning,
                        borderRadius:
                            BorderRadius.circular(AppTokens.badgeRadius),
                      ),
                      child: Text(
                        'Pengingat!',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: operational.onWarning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Pengecekan Unit\nBerkala',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: operational.warning,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _countdownDays,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: operational.onWarning,
                    ),
                  ),
                  Text(
                    'Hari Lagi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: operational.onWarning,
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

  Widget _buildUnitStatusSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Unit Blower',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    _totalMonitored == 0 && !_loading
                        ? 'Belum ada unit terdata'
                        : 'Total $_totalMonitored mesin aktif dipantau',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Status data inventaris terkini',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space8,
                  vertical: AppTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: operational.success,
                  borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                ),
                child: Text(
                  'Data Terkini',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: operational.onSuccess,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - AppTokens.space16) / 3;
            return Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                _buildStatusCard(
                  context,
                  width,
                  Icons.check_rounded,
                  _operatingCount,
                  'Beroperasi',
                  'Kondisi prima',
                  _totalMonitored,
                  operational.success,
                  operational.onSuccess,
                ),
                _buildStatusCard(
                  context,
                  width,
                  Icons.build_rounded,
                  _serviceCount,
                  'Perlu Servis',
                  'Jadwal dekat',
                  _totalMonitored,
                  operational.warning,
                  operational.onWarning,
                ),
                _buildStatusCard(
                  context,
                  width,
                  Icons.warning_amber_rounded,
                  _problemCount,
                  'Kendala',
                  'Cek fisik',
                  _totalMonitored,
                  operational.danger,
                  operational.onDanger,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    double width,
    IconData icon,
    int count,
    String title,
    String subtitle,
    int total,
    Color badgeBackground,
    Color badgeForeground,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percentage = total > 0 ? '${((count / total) * 100).round()}%' : '0%';
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: badgeForeground),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4,
                      vertical: AppTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius:
                          BorderRadius.circular(AppTokens.badgeRadius),
                    ),
                    child: Text(
                      percentage,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Text('$count', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppTokens.space4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingOrdersSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: AppTokens.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Orderan Mendatang',
                      style: theme.textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space8,
                      vertical: AppTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppTokens.badgeRadius),
                    ),
                    child: Text(
                      '${_upcomingOrders.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => UpcomingOrdersScreen(
                      gateway: widget.gateway,
                      user: widget.user,
                    ),
                  ),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        if (_upcomingOrders.isNotEmpty)
          ..._upcomingOrders.take(3).map(
                (order) => _buildOrderCard(context, order),
              )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 32, color: colors.outline),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    'Tidak ada orderan mendatang saat ini',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Jadwal pemasangan diperbarui otomatis saat ada orderan baru.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>()!;
    final hasMaps =
        order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
    final hasWa = order.cleanWhatsapp.isNotEmpty;
    final isPast = order.isPast;
    final statusText = isPast
        ? (order.isCompletedOrCancelled
            ? (order.statusOrderan ?? 'Selesai')
            : 'Selesai / Lewat')
        : ((order.statusOrderan != null && order.statusOrderan!.isNotEmpty)
            ? order.statusOrderan!
            : 'Terjadwal');
    final statusBackground =
        isPast ? colors.secondaryContainer : operational.success;
    final statusForeground =
        isPast ? colors.onSecondaryContainer : operational.onSuccess;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: order.displayCode,
                        children: [
                          TextSpan(
                            text: ' • ${order.jumlahUnit} Unit',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          TextSpan(
                            text: ' (${order.durasiSewaText})',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Semantics(
                    label: 'Status order: $statusText',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space8,
                        vertical: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius:
                            BorderRadius.circular(AppTokens.badgeRadius),
                      ),
                      child: Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Text(order.namaEvent, style: theme.textTheme.titleMedium),
              if (order.namaClient != null && order.namaClient!.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Klien: ${order.namaClient}${order.nomorWhatsapp != null && order.nomorWhatsapp!.isNotEmpty ? ' • ${order.nomorWhatsapp}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (order.alamat != null && order.alamat!.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: AppTokens.space4),
                    Expanded(
                      child: Text(
                        order.alamat!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.space12),
              const Divider(height: 1),
              const SizedBox(height: AppTokens.space8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      order.dayDateYear,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hasMaps)
                    IconButton(
                      onPressed: order.launchMaps,
                      icon: const Icon(Icons.near_me_rounded),
                      tooltip: 'Maps',
                    ),
                  if (hasWa)
                    IconButton(
                      onPressed: order.launchWhatsApp,
                      icon: const Icon(Icons.chat_rounded),
                      tooltip: 'WA',
                    ),
                  if (!hasMaps && !hasWa)
                    const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
