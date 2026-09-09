import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/bottom_nav_bar.dart';
import '../../shared/pressable.dart';
import '../maintenance/checking_screen.dart';
import '../components/component.dart';

class ActionCenterScreen extends StatefulWidget {
  const ActionCenterScreen({
    super.key,
    required this.gateway,
    required this.onNavigateToTab,
    required this.onOpenScanner,
    this.showBottomNav = true,
  });

  final MaintenanceGateway gateway;
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenScanner;
  final bool showBottomNav;

  @override
  State<ActionCenterScreen> createState() => _ActionCenterScreenState();
}

class _ActionCenterScreenState extends State<ActionCenterScreen> {
  int activeSegment = 0; // 0 = Update Kondisi, 1 = Servis
  final searchController = TextEditingController();

  int completedTasks = 0;
  int totalTasks = 0;
  int servicePendingCount = 0;
  bool isLoading = false;
  Object? error;
  static const int _pageSize = 6;
  int _visibleUpdateCount = 6;
  int _visibleServiceCount = 6;
  bool _isLoadingMore = false;
  final ScrollController scrollController = ScrollController();
  List<Map<String, dynamic>> updateKondisiList = [];
  List<Map<String, dynamic>> serviceList = [];

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    loadData();
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 150) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    if (activeSegment == 0) {
      final total = _getFilteredUpdateItems().length;
      if (_visibleUpdateCount < total) {
        setState(() => _isLoadingMore = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _visibleUpdateCount =
                  math.min(_visibleUpdateCount + _pageSize, total);
              _isLoadingMore = false;
            });
          }
        });
      }
    } else {
      final total = _getFilteredServiceItems().length;
      if (_visibleServiceCount < total) {
        setState(() => _isLoadingMore = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _visibleServiceCount =
                  math.min(_visibleServiceCount + _pageSize, total);
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredUpdateItems() {
    final query = searchController.text.trim().toLowerCase();
    return updateKondisiList.where((item) {
      if (query.isEmpty) return true;
      return (item['code'] as String).toLowerCase().contains(query) ||
          (item['description'] as String).toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredServiceItems() {
    final query = searchController.text.trim().toLowerCase();
    return serviceList.where((item) {
      if (query.isEmpty) return true;
      return (item['code'] as String).toLowerCase().contains(query) ||
          (item['description'] as String).toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final summary = await widget.gateway.fetchTasksSummary();
      if (!mounted) return;
      if (summary.isNotEmpty) {
        if (summary['total'] is int) totalTasks = summary['total'] as int;
        if (summary['completed'] is int) {
          completedTasks = summary['completed'] as int;
        }
        if (summary['items'] is List) {
          updateKondisiList = (summary['items'] as List).map((t) {
            final code = (t['code'] ?? '').toString();
            final kind = (t['kind'] ?? '').toString();
            final status = (t['status'] ?? '').toString();
            final isDone = status == 'completed' || status == 'completed_late';
            return {
              'id': (t['componentId'] ?? t['id'] ?? '').toString(),
              'code': code,
              'kind': 'Komponen $kind Utama',
              'condition': isDone ? 'Selesai' : 'Perlu Diperiksa',
              'conditionColor': isDone
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              'description':
                  'Tugas pemeriksaan periode ini untuk kelayakan unit $code.',
              'lastChecked': isDone ? 'Selesai diperiksa' : 'Jadwal periode aktif',
              'taskId': (t['id'] ?? '').toString(),
            };
          }).toList();
        }
      }

      final components = await widget.gateway.fetchComponents();
      if (!mounted) return;
      if (components.isNotEmpty) {
        final needsService = components.where((c) {
          final cond = (c['kondisi'] ?? c['condition'] ?? '').toString();
          return {'Service', 'Rusak Berat', 'Rusak Ringan'}.contains(cond);
        }).toList();

        servicePendingCount = needsService.length;
        serviceList = needsService.map((c) {
          final cond =
              (c['kondisi'] ?? c['condition'] ?? 'Service').toString();
          final color = cond == 'Service' || cond == 'Rusak Berat'
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B);
          final updated = (c['updated_at'] ?? '').toString();
          final dateStr =
              updated.length >= 10 ? updated.substring(0, 10) : 'Tercatat';
          return {
            'id': (c['id'] ?? '').toString(),
            'code': (c['nomor_stiker'] ?? c['code'] ?? '').toString(),
            'kind':
                'Komponen ${(c['jenis_komponen'] ?? c['kind'] ?? '')} Utama',
            'condition':
                cond == 'Service' ? 'Perlu Servis' : (cond == 'Rusak Berat' ? 'Gangguan Fungsi' : 'Rusak Ringan'),
            'conditionColor': color,
            'description': (c['keterangan'] ??
                    c['note'] ??
                    'Terindikasi kendala fisik, membutuhkan tindakan servis teknisi.')
                .toString(),
            'reporter': dateStr,
          };
        }).toList();
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> openActionForm(Map<String, dynamic> item, bool isService) async {
    final compId = (item['id'] ?? '').toString();
    if (compId.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF147CC1)),
      ),
    );

    Component? component;
    try {
      component = await Component.load(widget.gateway, compId);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(e))),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckingScreen(
          gateway: widget.gateway,
          component: component!,
          service: isService,
          taskId: item['taskId'] as String?,
        ),
      ),
    );

    if (res == true && mounted) {
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadData,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(context),
                        const SizedBox(height: 14),
                        _buildSegmentedControl(context),
                        const SizedBox(height: 14),
                        _buildSearchBarWithScan(context),
                        const SizedBox(height: 14),
                        if (activeSegment == 0) ...[
                          _buildPeriodSummaryBanner(context),
                          const SizedBox(height: 14),
                          _buildUpdateKondisiList(context),
                        ] else ...[
                          _buildServicePriorityBanner(context),
                          const SizedBox(height: 14),
                          _buildServisList(context),
                        ],
                        const SizedBox(height: 110), // Spacing for bottom nav
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNavBar(
              currentIndex: 2,
              onNavigateToTab: widget.onNavigateToTab,
              onOpenScanner: widget.onOpenScanner,
            )
          : null,
    );
  }

  // Header: "Pusat Tindakan \n Pencatatan kondisi & perbaikan unit" + Option Menu
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat Tindakan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pencatatan kondisi & perbaikan unit',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PressableScale(
          onTap: () {},
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2-Segment Control: [Update Kondisi] & [Servis]
  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Segment 0: Update Kondisi
          Expanded(
            child: PressableScale(
              onTap: () => setState(() => activeSegment = 0),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: activeSegment == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: activeSegment == 0
                      ? const [
                          BoxShadow(
                            color: Color(0x0F0F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: activeSegment == 0
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Perbarui Kondisi',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: activeSegment == 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: activeSegment == 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Segment 1: Servis
          Expanded(
            child: PressableScale(
              onTap: () => setState(() => activeSegment = 1),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: activeSegment == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: activeSegment == 1
                      ? const [
                          BoxShadow(
                            color: Color(0x0F0F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_rounded,
                      size: 16,
                      color: activeSegment == 1
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Servis',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: activeSegment == 1
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: activeSegment == 1
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
    );
  }

  // Search Input + Quick Scan Button
  Widget _buildSearchBarWithScan(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
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
                      hintText: 'Ketik kode (K-xx, B-xx, T-xx)...',
                      hintStyle: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: widget.onOpenScanner,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Banner: "Pemeriksaan Periode: X/Y Selesai" + Z%
  Widget _buildPeriodSummaryBanner(BuildContext context) {
    final pct =
        totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pemeriksaan Periode Berjalan: $completedTasks/$totalTasks Selesai',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$pct%',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // Banner: "Antrean Unit Bermasalah: 5 Unit Butuh Tindakan" + "Prioritas"
  Widget _buildServicePriorityBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Antrean Unit Bermasalah: $servicePendingCount Unit Butuh Tindakan',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Prioritas',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  // Update Kondisi Items List
  Widget _buildUpdateKondisiList(BuildContext context) {
    if (isLoading && updateKondisiList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF147CC1)),
              SizedBox(height: 14),
              Text(
                'Memuat daftar tugas pemeriksaan...',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null && updateKondisiList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              failureMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF147CC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final items = _getFilteredUpdateItems();
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_turned_in_outlined,
                  size: 44, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Tidak ada tugas pemeriksaan aktif',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Jadwal berkala dimulai pada Sabtu keempat setiap bulan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = items.take(_visibleUpdateCount).toList();

    return Column(
      children: [
        ...visibleItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['code'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            item['kind'] as String,
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
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['conditionColor'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item['condition'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['description'] as String,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['lastChecked'] as String,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => openActionForm(item, false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Perbarui Kondisi',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (_isLoadingMore && activeSegment == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Memuat tugas selanjutnya...',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else if (_visibleUpdateCount < items.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: InkWell(
                onTap: _loadMore,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Muat Lebih Banyak (${items.length - _visibleUpdateCount} tugas tersisa)',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (items.length > _pageSize)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Menampilkan seluruh ${items.length} tugas pemeriksaan',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Servis Items List (with "Catat Servis" button)
  Widget _buildServisList(BuildContext context) {
    if (isLoading && serviceList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF147CC1)),
              SizedBox(height: 14),
              Text(
                'Memuat antrean unit bermasalah...',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null && serviceList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              failureMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF147CC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final items = _getFilteredServiceItems();
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 44, color: Color(0xFF10B981)),
              SizedBox(height: 12),
              Text(
                'Semua unit dalam kondisi prima',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tidak ada komponen yang sedang membutuhkan servis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = items.take(_visibleServiceCount).toList();

    return Column(
      children: [
        ...visibleItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['code'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            item['kind'] as String,
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
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['conditionColor'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['condition'] as String,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['description'] as String,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['reporter'] as String,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => openActionForm(item, true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.build_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Catat Servis',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (_isLoadingMore && activeSegment == 1)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Memuat unit servis selanjutnya...',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else if (_visibleServiceCount < items.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: InkWell(
                onTap: _loadMore,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Muat Lebih Banyak (${items.length - _visibleServiceCount} unit tersisa)',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (items.length > _pageSize)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Menampilkan seluruh ${items.length} unit butuh servis',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
