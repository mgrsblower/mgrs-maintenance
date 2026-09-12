import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../schedule/order_detail_screen.dart';
import '../schedule/order_model.dart';

const _fallbackOperationalColors = OperationalColors(
  success: AppTokens.successSurface,
  onSuccess: AppTokens.success,
  warning: AppTokens.warningSurface,
  onWarning: AppTokens.warning,
  danger: AppTokens.dangerSurface,
  onDanger: AppTokens.danger,
);

OperationalColors _operationalColors(BuildContext context) =>
    Theme.of(context).extension<OperationalColors>() ??
    _fallbackOperationalColors;

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
      final allOrders = await widget.gateway.fetchUpcomingOrders(
        limit: 50,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allOrders = allOrders;
        _upcomingOrders = allOrders.where((order) => order.isUpcoming).toList();
        _pastOrders = allOrders.where((order) => order.isPast).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = failureMessage(error);
        _isLoading = false;
      });
    }
  }

  int get _thisMonthOrdersCount {
    final now = DateTime.now();
    return _allOrders.where((order) {
      final date = order.tanggalPemasangan;
      return date != null && date.year == now.year && date.month == now.month;
    }).length;
  }

  int get _todayOrdersCount {
    final now = DateTime.now();
    return _upcomingOrders.where((order) {
      final date = order.tanggalPemasangan;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi!';
    if (hour < 15) return 'Selamat Siang!';
    if (hour < 18) return 'Selamat Sore!';
    return 'Selamat Malam!';
  }

  static String _formatMonthName(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTokens.space16),
                    _buildUserHeader(context),
                    const SizedBox(height: AppTokens.space16),
                    if (_isLoading)
                      const SizedBox(
                        height: 420,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildError(context)
                    else ...[
                      _buildMonthlySummary(context),
                      const SizedBox(height: AppTokens.space12),
                      _buildQuickLinks(context),
                      const SizedBox(height: AppTokens.space24),
                      _buildOrderSummary(context),
                      const SizedBox(height: AppTokens.space24),
                      _buildOrderGroup(
                        context,
                        title: 'Orderan Mendatang',
                        orders: _upcomingOrders,
                        emptyMessage: 'Tidak ada orderan mendatang saat ini',
                        emptyDescription:
                            'Jadwal pemasangan diperbarui otomatis saat ada orderan baru.',
                        showAllAction: true,
                      ),
                      if (_pastOrders.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.space24),
                        _buildOrderGroup(
                          context,
                          title: 'Riwayat Orderan',
                          orders: _pastOrders,
                          emptyMessage: 'Belum ada riwayat orderan',
                          emptyDescription: 'Orderan yang sudah lewat akan tampil di sini.',
                          showAllAction: false,
                        ),
                      ],
                    ],
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
            const SizedBox(height: AppTokens.space12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            OutlinedButton(
              onPressed: () => _loadData(forceRefresh: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
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
              constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                    child: Text(widget.user.initials, style: theme.textTheme.labelLarge),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _getGreeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ],
                        ),
                        Text(
                          widget.user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Mode PIC • Order & Invoice',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
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
        final operational = _operationalColors(sheetContext);
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
                    Expanded(child: Text('Profil Pengguna', style: theme.textTheme.titleLarge)),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                          child: Text(widget.user.initials, style: theme.textTheme.titleMedium?.copyWith(color: colors.onSecondary)),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.displayName, style: theme.textTheme.titleMedium),
                              const SizedBox(height: AppTokens.space8),
                              Wrap(
                                spacing: AppTokens.space8,
                                runSpacing: AppTokens.space4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                                    decoration: BoxDecoration(
                                      color: colors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                                    ),
                                    child: Text(widget.user.role, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700)),
                                  ),
                                  if (widget.user.username != null)
                                    Text('@${widget.user.username}', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
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
                    borderRadius: BorderRadius.circular(AppTokens.controlRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: operational.onSuccess),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          widget.user.isAdmin
                              ? 'Sistem MGRS • Akun Administrator'
                              : 'Sistem MGRS • Terhubung (Mode PIC)',
                          style: theme.textTheme.labelLarge?.copyWith(color: operational.onSuccess),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.user.isAdmin && widget.onSwitchAdminMode != null) ...[
                  const SizedBox(height: AppTokens.space16),
                  Text('Mode Tampilan (Khusus Admin)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Pilih peran tampilan operasional yang ingin Anda akses:',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  SegmentedButton<AdminAppMode>(
                    segments: const [
                      ButtonSegment(value: AdminAppMode.pic, icon: Icon(Icons.event_note_rounded), label: Text('Mode PIC')),
                      ButtonSegment(value: AdminAppMode.service, icon: Icon(Icons.build_rounded), label: Text('Mode Servis')),
                    ],
                    selected: {widget.adminMode ?? AdminAppMode.pic},
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
                  style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error)),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun MGRS?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              Navigator.of(sheetContext).pop();
              await widget.gateway.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                    ),
                    child: Text(_formatMonthName(DateTime.now()), style: theme.textTheme.labelSmall?.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text('Total Orderan\nBulan Ini', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: colors.secondaryContainer, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_thisMonthOrdersCount', style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSecondaryContainer)),
                  Text('Orderan', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSecondaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickLinks(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onOpenOrdersTab,
            icon: const Icon(Icons.event_note_rounded),
            label: const Text('Orderan'),
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onOpenInvoicesTab,
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Invoice'),
          ),
        ),
      ],
    );
  }


  Widget _buildOrderSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final total = _allOrders.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Orderan', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    total == 0 ? 'Belum ada data orderan' : 'Total $total orderan tercatat di sistem',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
              decoration: BoxDecoration(color: operational.success, borderRadius: BorderRadius.circular(AppTokens.badgeRadius)),
              child: Text('Data Terkini', style: theme.textTheme.labelSmall?.copyWith(color: operational.onSuccess, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppTokens.space16) / 3;
            return Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                _buildSummaryCard(context, itemWidth, Icons.assignment_outlined, _allOrders.length, 'Total Order', 'Semua riwayat', colors.secondaryContainer, colors.onSecondaryContainer),
                _buildSummaryCard(context, itemWidth, Icons.event_available_rounded, _upcomingOrders.length, 'Akan Datang', '$_todayOrdersCount hari ini', operational.warning, operational.onWarning),
                _buildSummaryCard(context, itemWidth, Icons.check_circle_outline_rounded, _pastOrders.length, 'Selesai', 'Event beres', operational.success, operational.onSuccess),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, double width, IconData icon, int count, String title, String subtitle, Color background, Color foreground) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(height: AppTokens.space12),
              Text('$count', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppTokens.space4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space4),
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppTokens.badgeRadius)),
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderGroup(BuildContext context, {required String title, required List<OrderanSewa> orders, required String emptyMessage, required String emptyDescription, required bool showAllAction}) {
    final theme = Theme.of(context);
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
                  Text(title, style: theme.textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(AppTokens.badgeRadius)),
                    child: Text('${orders.length}', style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
            ),
            if (showAllAction)
              TextButton(onPressed: widget.onOpenOrdersTab, child: const Text('Lihat Semua')),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        if (orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 32, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: AppTokens.space8),
                  Text(emptyMessage, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTokens.space4),
                  Text(emptyDescription, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          )
        else
          ...orders.take(showAllAction ? 4 : 3).map((order) => _buildOrderCard(context, order)),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final hasMaps = order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
    final hasWa = order.cleanWhatsapp.isNotEmpty;
    final isPast = order.isPast;
    final statusText = order.isCancelled
        ? 'Dibatalkan'
        : isPast
            ? (order.isCompletedOrCancelled ? (order.statusOrderan ?? 'Selesai') : 'Selesai / Lewat')
            : ((order.statusOrderan?.isNotEmpty ?? false) ? order.statusOrderan! : 'Terjadwal');
    final statusBackground = order.isCancelled
        ? operational.danger
        : isPast
            ? colors.secondaryContainer
            : operational.success;
    final statusForeground = order.isCancelled
        ? operational.onDanger
        : isPast
            ? colors.onSecondaryContainer
            : operational.onSuccess;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order, gateway: widget.gateway, user: widget.user),
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
                          TextSpan(text: ' • ${order.jumlahUnit} Unit', style: TextStyle(color: colors.onSurfaceVariant)),
                          TextSpan(text: ' (${order.durasiSewaText})', style: TextStyle(color: colors.onSurfaceVariant)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                    decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(AppTokens.badgeRadius)),
                    child: Text(statusText, style: theme.textTheme.labelSmall?.copyWith(color: statusForeground, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Text(order.namaEvent, style: theme.textTheme.titleMedium),
              if (order.namaClient?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Klien: ${order.namaClient}${order.nomorWhatsapp?.isNotEmpty ?? false ? ' • ${order.nomorWhatsapp}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (order.alamat?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppTokens.space8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: colors.onSurfaceVariant),
                    const SizedBox(width: AppTokens.space4),
                    Expanded(child: Text(order.alamat!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.space12),
              const Divider(),
              const SizedBox(height: AppTokens.space8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(child: Text(order.dayDateYear, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium)),
                  if (hasMaps) IconButton(onPressed: order.launchMaps, icon: const Icon(Icons.near_me_rounded), tooltip: 'Maps'),
                  if (hasWa) IconButton(onPressed: order.launchWhatsApp, icon: const Icon(Icons.chat_rounded), tooltip: 'WA'),
                  if (!hasMaps && !hasWa) const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
