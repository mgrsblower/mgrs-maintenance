import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'order_model.dart';

class UpcomingOrdersScreen extends StatefulWidget {
  const UpcomingOrdersScreen({
    super.key,
    required this.gateway,
    this.user,
  });

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
      final fetched = await widget.gateway
          .fetchUpcomingOrders(limit: 50, forceRefresh: true);
      if (mounted) {
        setState(() {
          orders = fetched;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Daftar orderan belum dapat dimuat. Periksa koneksi internet lalu coba lagi.';
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
          (o.namaClient != null && o.namaClient!.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _openCreateOrder() async {
    if (widget.user == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          gateway: widget.gateway,
          user: widget.user!,
        ),
      ),
    );
    if (created == true) loadOrders();
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
              left: index == 0 ? 0 : 4,
              right: index == filters.length - 1 ? 0 : 4,
            ),
            child: PressableScale(
              onTap: () => setState(() => activeFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
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
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
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
    final list = filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: _buildSearchBar(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: _buildFilterChips(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadOrders,
                color: const Color(0xFF147CC1),
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF147CC1)),
                      )
                    : error != null
                        ? _buildErrorView(context)
                        : list.isEmpty
                            ? _buildEmptyView(context)
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
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

  Widget _buildTopBar(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (canPop) ...[
                PressableScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Orderan Mendatang',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jadwal Pemasangan & Sewa',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.user?.canManageOrders == true)
            PressableScale(
              onTap: _openCreateOrder,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF147CC1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF147CC1).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Orderan Baru',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            PressableScale(
              onTap: loadOrders,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Cari acara, lokasi, atau PIC...',
                hintStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                setState(() {});
              },
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF94A3B8)),
            ),
        ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
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
                color: Color(0x06000000),
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

              // Detail Klien
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
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
              SizedBox(height: 14),
              Text(
                'Belum Ada Orderan Mendatang',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Daftar orderan sewa akan otomatis muncul saat jadwal pemasangan dibuat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              error ?? 'Terjadi kesalahan saat memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF147CC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
