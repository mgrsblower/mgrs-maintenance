import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_search_field.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'order_model.dart';

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
          error = 'Daftar orderan gagal dimuat';
          isLoading = false;
        });
      }
    }
  }

  List<OrderanSewa> get filteredOrders {
    final q = searchController.text.trim().toLowerCase();
    return orders.where((o) {
      final matchesFilter = switch (activeFilter) {
        'Mendatang' => o.isUpcoming,
        'Selesai' => o.isPast,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return o.namaEvent.toLowerCase().contains(q) ||
          (o.alamat != null && o.alamat!.toLowerCase().contains(q)) ||
          (o.namaPic != null && o.namaPic!.toLowerCase().contains(q)) ||
          (o.namaClient != null && o.namaClient!.toLowerCase().contains(q)) ||
          o.displayCode.toLowerCase().contains(q);
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

  Widget _buildTopHeader(BuildContext context) {
    final canManage = widget.user?.canManageOrders == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MgrsSpacing.md,
        MgrsSpacing.sm,
        MgrsSpacing.md,
        MgrsSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 320;
          final titleCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Orderan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Jadwal pemasangan dan persewaan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MgrsColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionBtn = canManage
              ? FilledButton.icon(
                  onPressed: _openCreateOrder,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Buat order',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: MgrsColors.action,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MgrsSpacing.sm,
                      vertical: MgrsSpacing.xs,
                    ),
                    minimumSize: const Size(0, MgrsSizes.minTouch),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MgrsRadii.pill),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: loadOrders,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Muat ulang data',
                  constraints: const BoxConstraints.tightFor(
                    width: MgrsSizes.minTouch,
                    height: MgrsSizes.minTouch,
                  ),
                );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleCol,
                const SizedBox(height: MgrsSpacing.xs),
                actionBtn,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleCol),
              actionBtn,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = ['Semua', 'Mendatang', 'Selesai'];
    final upcomingCount = orders.where((o) => o.isUpcoming).length;
    final pastCount = orders.where((o) => o.isPast).length;

    return Row(
      children: filters.asMap().entries.map((entry) {
        final index = entry.key;
        final f = entry.value;
        final isSelected = activeFilter == f;
        final count = switch (f) {
          'Mendatang' => upcomingCount,
          'Selesai' => pastCount,
          _ => orders.length,
        };

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == filters.length - 1 ? 0 : 2,
            ),
            child: InkWell(
              onTap: () => setState(() => activeFilter = f),
              borderRadius: BorderRadius.circular(MgrsRadii.pill),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: MgrsSizes.minTouch,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? MgrsColors.ink : MgrsColors.surface,
                  borderRadius: BorderRadius.circular(MgrsRadii.pill),
                  border: Border.all(
                    color: isSelected ? MgrsColors.ink : MgrsColors.line,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected ? Colors.white : MgrsColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : MgrsColors.canvas,
                          borderRadius: BorderRadius.circular(MgrsRadii.pill),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : MgrsColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final list = filteredOrders;

    return Scaffold(
      backgroundColor: MgrsColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MgrsSpacing.md,
                vertical: MgrsSpacing.xs,
              ),
              child: MgrsSearchField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                hintText: 'Cari acara, lokasi, atau PIC...',
                onClear: () => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MgrsSpacing.md,
                MgrsSpacing.xs,
                MgrsSpacing.md,
                MgrsSpacing.xs,
              ),
              child: _buildFilterChips(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadOrders,
                color: MgrsColors.action,
                child: isLoading
                    ? LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: const Center(
                                  child: MgrsStateView.loading(
                                    title: 'Memuat daftar orderan...',
                                  ),
                                ),
                              ),
                            ),
                      )
                    : error != null
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: MgrsStateView.error(
                                title: 'Daftar orderan gagal dimuat',
                                message:
                                    'Periksa koneksi internet Anda lalu coba lagi.',
                                actionLabel: 'Muat data terbaru',
                                onAction: loadOrders,
                              ),
                            ),
                          ),
                        ),
                      )
                    : orders.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: MgrsStateView.empty(
                                title: 'Belum ada orderan mendatang',
                                message:
                                    'Belum ada jadwal sewa blower tersimpan.',
                                actionLabel: 'Buat orderan baru',
                                onAction: _openCreateOrder,
                              ),
                            ),
                          ),
                        ),
                      )
                    : list.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: MgrsStateView.noResults(
                                    query: searchController.text.isNotEmpty
                                        ? searchController.text
                                        : activeFilter,
                                    onReset: () {
                                      setState(() {
                                        searchController.clear();
                                        activeFilter = 'Semua';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          MgrsSpacing.md,
                          MgrsSpacing.xs,
                          MgrsSpacing.md,
                          80,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(context, list[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
    final statusText =
        order.statusOrderan != null && order.statusOrderan!.isNotEmpty
        ? order.statusOrderan!
        : (order.isPast ? 'Selesai' : 'Terjadwal');

    final statusTone = order.isCancelled
        ? MgrsStatusTone.danger
        : (order.statusOrderan == 'Selesai' || order.isPast)
        ? MgrsStatusTone.success
        : MgrsStatusTone.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: MgrsSpacing.sm),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(
                order: order,
                orderId: order.id,
                gateway: widget.gateway,
                user: widget.user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        child: Container(
          padding: const EdgeInsets.all(MgrsSpacing.sm + 4),
          decoration: BoxDecoration(
            color: MgrsColors.surface,
            borderRadius: BorderRadius.circular(MgrsRadii.card),
            border: Border.all(color: MgrsColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: MgrsSpacing.xs,
                runSpacing: 4,
                children: [
                  Text(
                    order.displayCode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MgrsColors.action,
                    ),
                  ),
                  MgrsStatusBadge(statusText, tone: statusTone),
                ],
              ),
              const SizedBox(height: MgrsSpacing.xs),
              Text(
                order.namaEvent,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.ink,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.namaClient != null &&
                  order.namaClient!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  order.namaClient!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: MgrsColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: MgrsSpacing.xs),
              const Divider(height: 1, color: MgrsColors.line),
              const SizedBox(height: MgrsSpacing.xs),
              Wrap(
                spacing: MgrsSpacing.sm,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: MgrsColors.muted,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        TextSpan(
                          text: order.tanggalPemasangan != null
                              ? '${order.tanggalPemasangan!.day}/${order.tanggalPemasangan!.month}/${order.tanggalPemasangan!.year}'
                              : 'Tanggal belum ditentukan',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MgrsColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.air_rounded,
                            size: 14,
                            color: MgrsColors.muted,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        TextSpan(
                          text:
                              '${order.jumlahUnit} Unit (${order.durasiSewaText})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MgrsColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (order.alamat != null && order.alamat!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: MgrsColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.alamat!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: MgrsColors.muted,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
