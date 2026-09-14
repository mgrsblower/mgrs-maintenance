import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_search_field.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
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

class _ActionCenterScreenState extends State<ActionCenterScreen>
    with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

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
              _visibleUpdateCount = math.min(
                _visibleUpdateCount + _pageSize,
                total,
              );
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
              _visibleServiceCount = math.min(
                _visibleServiceCount + _pageSize,
                total,
              );
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

  Future<void> loadData({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final summary = await widget.gateway.fetchTasksSummary(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      totalTasks = summary['total'] is int ? summary['total'] as int : 0;
      completedTasks = summary['completed'] is int
          ? summary['completed'] as int
          : 0;
      final tasks = summary['items'] is List
          ? summary['items'] as List
          : const [];
      updateKondisiList = tasks.map((t) {
        final code = (t['code'] ?? '').toString();
        final kind = (t['kind'] ?? '').toString();
        final status = (t['status'] ?? '').toString();
        final isDone = status == 'completed' || status == 'completed_late';
        return {
          'id': (t['componentId'] ?? t['id'] ?? '').toString(),
          'code': code,
          'kind': 'Komponen $kind Utama',
          'condition': isDone ? 'Selesai' : 'Perlu Diperiksa',
          'description':
              'Tugas pemeriksaan periode ini untuk kelayakan unit $code.',
          'lastChecked': isDone ? 'Selesai diperiksa' : 'Jadwal periode aktif',
          'taskId': (t['id'] ?? '').toString(),
        };
      }).toList();

      final components = await widget.gateway.fetchComponents(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final needsService = components.where((c) {
        final cond = (c['kondisi'] ?? c['condition'] ?? '').toString();
        return {'Service', 'Rusak Berat', 'Rusak Ringan'}.contains(cond);
      }).toList();

      servicePendingCount = needsService.length;
      serviceList = needsService.map((c) {
        final cond = (c['kondisi'] ?? c['condition'] ?? 'Service').toString();
        final updated = (c['updated_at'] ?? '').toString();
        final dateStr = updated.length >= 10
            ? updated.substring(0, 10)
            : 'Tercatat';
        return {
          'id': (c['id'] ?? '').toString(),
          'code': (c['nomor_stiker'] ?? c['code'] ?? '').toString(),
          'kind': 'Komponen ${(c['jenis_komponen'] ?? c['kind'] ?? '')} Utama',
          'condition': cond == 'Service'
              ? 'Perlu Servis'
              : (cond == 'Rusak Berat' ? 'Gangguan Fungsi' : 'Rusak Ringan'),
          'description':
              (c['keterangan'] ??
                      c['note'] ??
                      'Terindikasi kendala fisik, membutuhkan tindakan servis teknisi.')
                  .toString(),
          'reporter': dateStr,
        };
      }).toList();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(e))));
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
    super.build(context);
    return Scaffold(
      backgroundColor: MgrsColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => loadData(forceRefresh: true),
                color: MgrsColors.operational,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MgrsSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: MgrsSpacing.md),
                        _buildHeader(context),
                        const SizedBox(height: MgrsSpacing.base),
                        _buildSegmentedControl(context),
                        const SizedBox(height: MgrsSpacing.md),
                        _buildSearchBarWithScan(context),
                        const SizedBox(height: MgrsSpacing.md),
                        if (activeSegment == 0) ...[
                          if (!isLoading || updateKondisiList.isNotEmpty) ...[
                            _buildPeriodSummaryBanner(context),
                            const SizedBox(height: MgrsSpacing.md),
                          ],
                          _buildUpdateKondisiList(context),
                        ] else ...[
                          if (!isLoading || serviceList.isNotEmpty) ...[
                            _buildServicePriorityBanner(context),
                            const SizedBox(height: MgrsSpacing.md),
                          ],
                          _buildServisList(context),
                        ],
                        const SizedBox(height: 110),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pusat Tindakan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: MgrsColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: MgrsSpacing.xs),
        Text(
          'Pencatatan kondisi dan perbaikan unit',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
        ),
      ],
    );
  }

  // 2-Segment Control: [Update Kondisi] & [Servis]
  Widget _buildSegmentedControl(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Jenis tindakan',
      child: Container(
        padding: const EdgeInsets.all(MgrsSpacing.xs),
        decoration: BoxDecoration(
          color: MgrsColors.line,
          borderRadius: BorderRadius.circular(MgrsRadii.compact),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegment(
                context,
                index: 0,
                icon: Icons.edit_note_rounded,
                label: 'Perbarui Kondisi',
              ),
            ),
            Expanded(
              child: _buildSegment(
                context,
                index: 1,
                icon: Icons.build_rounded,
                label: 'Servis',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = activeSegment == index;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: () => setState(() {
          activeSegment = index;
          _isLoadingMore = false;
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MgrsSizes.minTouch),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? MgrsColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(MgrsRadii.control),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MgrsSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? MgrsColors.ink : MgrsColors.muted,
                  ),
                  const SizedBox(width: MgrsSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? MgrsColors.ink : MgrsColors.muted,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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
  }

  // Search Input + Quick Scan Button
  Widget _buildSearchBarWithScan(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MgrsSearchField(
            controller: searchController,
            hintText: 'Cari kode komponen',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: MgrsSpacing.sm),
        IconButton.filledTonal(
          tooltip: 'Pindai kode komponen',
          onPressed: widget.onOpenScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
      ],
    );
  }

  // Banner: "Pemeriksaan Periode: X/Y Selesai" + Z%
  Widget _buildPeriodSummaryBanner(BuildContext context) {
    final pct = totalTasks > 0
        ? ((completedTasks / totalTasks) * 100).round()
        : 0;
    return _buildSummaryBanner(
      context,
      icon: Icons.check_circle_outline,
      text:
          'Pemeriksaan periode berjalan: $completedTasks dari $totalTasks selesai',
      trailing: '$pct%',
      foreground: MgrsColors.success,
      background: MgrsColors.successSoft,
    );
  }

  // Banner: "Antrean Unit Bermasalah: 5 Unit Butuh Tindakan" + "Prioritas"
  Widget _buildServicePriorityBanner(BuildContext context) {
    return _buildSummaryBanner(
      context,
      icon: Icons.warning_amber_rounded,
      text: '$servicePendingCount unit membutuhkan tindakan servis',
      trailing: 'Prioritas',
      foreground: MgrsColors.danger,
      background: MgrsColors.dangerSoft,
    );
  }

  Widget _buildSummaryBanner(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String trailing,
    required Color foreground,
    required Color background,
  }) {
    return Semantics(
      container: true,
      label: '$text. $trailing',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(MgrsSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(MgrsRadii.compact),
          ),
          child: Wrap(
            spacing: MgrsSpacing.sm,
            runSpacing: MgrsSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                trailing,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update Kondisi Items List
  Widget _buildUpdateKondisiList(BuildContext context) {
    if (isLoading && updateKondisiList.isEmpty) {
      return const MgrsStateView.loading(
        title: 'Memuat daftar tugas pemeriksaan...',
      );
    }
    if (error != null && updateKondisiList.isEmpty) {
      return MgrsStateView.error(
        title: 'Tugas pemeriksaan gagal dimuat',
        message: 'Periksa koneksi lalu muat data terbaru.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadData(forceRefresh: true),
      );
    }
    final items = _getFilteredUpdateItems();
    if (items.isEmpty) {
      final query = searchController.text.trim();
      if (updateKondisiList.isNotEmpty && query.isNotEmpty) {
        return MgrsStateView.noResults(
          query: query,
          onReset: () => setState(() {
            searchController.clear();
            _visibleUpdateCount = _pageSize;
          }),
        );
      }
      return MgrsStateView.empty(
        title: 'Belum ada tugas pemeriksaan',
        message: 'Tugas baru akan muncul saat jadwal pemeriksaan tersedia.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadData(forceRefresh: true),
      );
    }
    return _buildTaskList(context, items, isService: false);
  }

  // Servis Items List (with "Catat Servis" button)
  Widget _buildServisList(BuildContext context) {
    if (isLoading && serviceList.isEmpty) {
      return const MgrsStateView.loading(
        title: 'Memuat antrean unit bermasalah...',
      );
    }
    if (error != null && serviceList.isEmpty) {
      return MgrsStateView.error(
        title: 'Antrean servis gagal dimuat',
        message: 'Periksa koneksi lalu muat data terbaru.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadData(forceRefresh: true),
      );
    }
    final items = _getFilteredServiceItems();
    if (items.isEmpty) {
      final query = searchController.text.trim();
      if (serviceList.isNotEmpty && query.isNotEmpty) {
        return MgrsStateView.noResults(
          query: query,
          onReset: () => setState(() {
            searchController.clear();
            _visibleServiceCount = _pageSize;
          }),
        );
      }
      return MgrsStateView.empty(
        title: 'Belum ada unit dalam antrean servis',
        message: 'Unit yang membutuhkan perbaikan akan muncul di sini.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadData(forceRefresh: true),
      );
    }
    return _buildTaskList(context, items, isService: true);
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Map<String, dynamic>> items, {
    required bool isService,
  }) {
    final visibleCount = isService ? _visibleServiceCount : _visibleUpdateCount;
    final visibleItems = items.take(visibleCount);
    return Column(
      children: [
        for (final item in visibleItems)
          _buildTaskCard(context, item, isService),
        if (_isLoadingMore && activeSegment == (isService ? 1 : 0))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.base),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MgrsColors.operational,
                  ),
                ),
                const SizedBox(width: MgrsSpacing.sm),
                Flexible(
                  child: Text(
                    isService
                        ? 'Memuat unit servis selanjutnya...'
                        : 'Memuat tugas selanjutnya...',
                  ),
                ),
              ],
            ),
          )
        else if (visibleCount < items.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.md),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              label: Text(
                'Muat lebih banyak (${items.length - visibleCount} tersisa)',
              ),
            ),
          )
        else if (items.length > _pageSize)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.base),
            child: Text(
              'Seluruh ${items.length} ${isService ? 'unit servis' : 'tugas pemeriksaan'} ditampilkan',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isService,
  ) {
    final condition = item['condition'] as String;
    final tone = condition == 'Selesai'
        ? MgrsStatusTone.success
        : condition == 'Gangguan Fungsi'
        ? MgrsStatusTone.danger
        : MgrsStatusTone.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: MgrsSpacing.md),
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
                item['code'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MgrsColors.ink,
                ),
              ),
              MgrsStatusBadge(condition, tone: tone),
            ],
          ),
          const SizedBox(height: MgrsSpacing.xs),
          Text(
            item['kind'] as String,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
          ),
          const SizedBox(height: MgrsSpacing.md),
          Text(
            item['description'] as String,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MgrsColors.ink),
          ),
          const SizedBox(height: MgrsSpacing.md),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final metadata = Text(
                item[isService ? 'reporter' : 'lastChecked'] as String,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
              );
              final action = FilledButton.icon(
                onPressed: () => openActionForm(item, isService),
                icon: Icon(
                  isService ? Icons.build_rounded : Icons.check_rounded,
                  size: 18,
                ),
                label: Text(isService ? 'Catat servis' : 'Perbarui kondisi'),
                style: FilledButton.styleFrom(
                  backgroundColor: MgrsColors.operational,
                  minimumSize: const Size(0, MgrsSizes.minTouch),
                ),
              );
              if (constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metadata,
                    const SizedBox(height: MgrsSpacing.sm),
                    action,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: metadata),
                  const SizedBox(width: MgrsSpacing.sm),
                  Flexible(child: action),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
