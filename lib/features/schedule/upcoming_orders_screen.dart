import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'order_model.dart';

OperationalColors _operationalColors(BuildContext context) =>
    Theme.of(context).extension<OperationalColors>() ??
    const OperationalColors(
      success: AppTokens.successSurface,
      onSuccess: AppTokens.success,
      warning: AppTokens.warningSurface,
      onWarning: AppTokens.warning,
      danger: AppTokens.dangerSurface,
      onDanger: AppTokens.danger,
    );

class UpcomingOrdersScreen extends StatefulWidget {
  const UpcomingOrdersScreen({super.key, required this.gateway, this.user});

  final MaintenanceGateway gateway;
  final UserProfile? user;

  @override
  State<UpcomingOrdersScreen> createState() => _UpcomingOrdersScreenState();
}

class _UpcomingOrdersScreenState extends State<UpcomingOrdersScreen> {
  final TextEditingController searchController = TextEditingController();
  List<OrderanSewa> orders = [];
  String activeFilter = 'Semua';
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final fetched = await widget.gateway.fetchUpcomingOrders(
        limit: 50,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          orders = fetched;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error =
              'Daftar orderan belum dapat dimuat. Periksa koneksi internet lalu coba lagi.';
          isLoading = false;
        });
      }
    }
  }

  List<OrderanSewa> get filteredOrders {
    final query = searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesFilter = switch (activeFilter) {
        'Mendatang' => order.isUpcoming,
        'Selesai' => order.isPast,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return order.namaEvent.toLowerCase().contains(query) ||
          (order.alamat?.toLowerCase().contains(query) ?? false) ||
          (order.namaPic?.toLowerCase().contains(query) ?? false) ||
          (order.namaClient?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _openCreateOrder() async {
    if (widget.user == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateOrderScreen(gateway: widget.gateway, user: widget.user!),
      ),
    );
    if (created == true) loadOrders();
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filters = ['Semua', 'Mendatang', 'Selesai'];
    final upcomingCount = orders.where((order) => order.isUpcoming).length;
    final pastCount = orders.where((order) => order.isPast).length;

    return Row(
      children: filters.asMap().entries.map((entry) {
        final index = entry.key;
        final filter = entry.value;
        final isSelected = activeFilter == filter;
        final count = switch (filter) {
          'Mendatang' => upcomingCount,
          'Selesai' => pastCount,
          _ => orders.length,
        };
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : AppTokens.space4,
              right: index == filters.length - 1 ? 0 : AppTokens.space4,
            ),
            child: PressableScale(
              onTap: () => setState(() => activeFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(
                  minHeight: AppTokens.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.secondary : colors.surface,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppTokens.badgeRadius),
                  ),
                  border: Border.all(
                    color: isSelected ? colors.secondary : colors.outline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        filter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colors.onSecondary
                              : colors.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space4),
                    Text(
                      '$count',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? colors.onSecondary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final list = filteredOrders;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space16,
                vertical: AppTokens.space8,
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari acara, lokasi, atau PIC...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space16,
                0,
                AppTokens.space16,
                AppTokens.space8,
              ),
              child: _buildFilterChips(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadOrders,
                color: colors.primary,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? _buildErrorView(context)
                    : list.isEmpty
                    ? _buildEmptyView(context)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.space16,
                          AppTokens.space8,
                          AppTokens.space16,
                          AppTokens.space32,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(context, list[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space8,
        AppTokens.space16,
        AppTokens.space4,
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              tooltip: 'Kembali',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orderan Mendatang', style: theme.textTheme.headlineSmall),
                Text(
                  'Jadwal Pemasangan & Sewa',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          if (widget.user?.canManageOrders == true)
            FilledButton.icon(
              onPressed: _openCreateOrder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Orderan Baru'),
            )
          else
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: isLoading ? null : loadOrders,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final hasMaps = order.linkGmaps?.trim().isNotEmpty == true;
    final hasWhatsapp = order.cleanWhatsapp.isNotEmpty;
    final isPast = order.isPast;
    final statusText = order.isCancelled
        ? 'Dibatalkan'
        : isPast
        ? (order.isCompletedOrCancelled
              ? (order.statusOrderan ?? 'Selesai')
              : 'Selesai / Lewat')
        : (order.statusOrderan?.isNotEmpty == true
              ? order.statusOrderan!
              : 'Terjadwal');
    final statusSurface = order.isCancelled
        ? operational.danger
        : isPast
        ? colors.surfaceContainer
        : operational.success;
    final statusInk = order.isCancelled
        ? operational.onDanger
        : isPast
        ? colors.onSurfaceVariant
        : operational.onSuccess;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Card(
        child: InkWell(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppTokens.cardRadius),
          ),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(
                order: order,
                gateway: widget.gateway,
                user: widget.user,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${order.displayCode} • ${order.jumlahUnit} Unit (${order.durasiSewaText})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Chip(
                      label: Text(statusText),
                      backgroundColor: statusSurface,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: statusInk,
                      ),
                      side: BorderSide(color: statusInk),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space8),
                Text(order.namaEvent, style: theme.textTheme.titleMedium),
                if (order.namaClient?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space4),
                    child: Text(
                      'Klien: ${order.namaClient}${order.nomorWhatsapp?.isNotEmpty == true ? ' • ${order.nomorWhatsapp}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (order.alamat?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: AppTokens.space4),
                        Expanded(
                          child: Text(
                            order.alamat!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: Text(
                        order.dayDateYear,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    if (hasMaps)
                      IconButton(
                        tooltip: 'Maps',
                        onPressed: order.launchMaps,
                        icon: const Icon(Icons.near_me_rounded),
                      ),
                    if (hasWhatsapp)
                      IconButton(
                        tooltip: 'WhatsApp',
                        onPressed: order.launchWhatsApp,
                        icon: const Icon(Icons.chat_rounded),
                      ),
                    if (!hasMaps && !hasWhatsapp)
                      const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: AppTokens.space32),
        Icon(
          Icons.event_busy_rounded,
          size: 48,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppTokens.space12),
        Center(
          child: Text(
            'Belum Ada Orderan Mendatang',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space32),
          child: Text(
            'Daftar orderan sewa akan otomatis muncul saat jadwal pemasangan dibuat.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
            const SizedBox(height: AppTokens.space12),
            Text(
              error ?? 'Terjadi kesalahan saat memuat data',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
            const SizedBox(height: AppTokens.space12),
            OutlinedButton(
              onPressed: loadOrders,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
