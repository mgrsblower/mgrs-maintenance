import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/bottom_nav_bar.dart';
import '../maintenance/checking_screen.dart';
import '../components/component.dart';

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
  int activeSegment = 0;
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
              'tone': isDone ? 'success' : 'warning',
              'description':
                  'Tugas pemeriksaan periode ini untuk kelayakan unit $code.',
              'lastChecked': isDone
                  ? 'Selesai diperiksa'
                  : 'Jadwal periode aktif',
              'taskId': (t['id'] ?? '').toString(),
            };
          }).toList();
        }
      }

      final components = await widget.gateway.fetchComponents(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      if (components.isNotEmpty) {
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
            'kind':
                'Komponen ${(c['jenis_komponen'] ?? c['kind'] ?? '')} Utama',
            'condition': cond == 'Service'
                ? 'Perlu Servis'
                : (cond == 'Rusak Berat' ? 'Gangguan Fungsi' : 'Rusak Ringan'),
            'tone': cond == 'Rusak Ringan' ? 'warning' : 'danger',
            'description':
                (c['keterangan'] ??
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
    if (res == true && mounted) loadData();
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
          onRefresh: () => loadData(forceRefresh: true),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTokens.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTokens.space16),
                    _buildHeader(context),
                    const SizedBox(height: AppTokens.space16),
                    _buildSegmentedControl(context),
                    const SizedBox(height: AppTokens.space12),
                    _buildSearchBarWithScan(context),
                    const SizedBox(height: AppTokens.space16),
                    if (activeSegment == 0) ...[
                      _buildPeriodSummaryBanner(context),
                      const SizedBox(height: AppTokens.space16),
                      _buildUpdateKondisiList(context),
                    ] else ...[
                      _buildServicePriorityBanner(context),
                      const SizedBox(height: AppTokens.space16),
                      _buildServisList(context),
                    ],
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
              currentIndex: 2,
              onNavigateToTab: widget.onNavigateToTab,
              onOpenScanner: widget.onOpenScanner,
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pusat Tindakan', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Pencatatan kondisi & perbaikan unit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz_rounded),
          tooltip: 'Pilihan lainnya',
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.edit_note_rounded),
          label: Text('Perbarui Kondisi'),
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.build_rounded),
          label: Text('Servis'),
        ),
      ],
      selected: {activeSegment},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() => activeSegment = selection.first);
      },
    );
  }

  Widget _buildSearchBarWithScan(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ketik Kode...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        SizedBox(
          width: AppTokens.minTouchTarget,
          height: AppTokens.minTouchTarget,
          child: IconButton.filledTonal(
            onPressed: widget.onOpenScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Pindai kode',
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSummaryBanner(BuildContext context) {
    final operational = _operationalColors(context);
    final pct = totalTasks > 0
        ? ((completedTasks / totalTasks) * 100).round()
        : 0;
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
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
              'Pemeriksaan Periode Berjalan: $completedTasks/$totalTasks Selesai',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: operational.onSuccess),
            ),
          ),
          Text(
            '$pct%',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: operational.onSuccess),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePriorityBanner(BuildContext context) {
    final operational = _operationalColors(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: operational.danger,
        borderRadius: BorderRadius.circular(AppTokens.controlRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high_rounded, color: operational.onDanger),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(
              'Antrean Unit Bermasalah: $servicePendingCount Unit Butuh Tindakan',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: operational.onDanger),
            ),
          ),
          Text(
            'Prioritas',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: operational.onDanger),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateKondisiList(BuildContext context) {
    if (isLoading && updateKondisiList.isEmpty) {
      return _buildLoadingState(context, 'Memuat daftar tugas pemeriksaan...');
    }
    if (error != null && updateKondisiList.isEmpty) {
      return _buildErrorState(context);
    }
    final items = _getFilteredUpdateItems();
    if (items.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.assignment_turned_in_outlined,
        'Tidak ada tugas pemeriksaan aktif',
        'Jadwal berkala dimulai pada Sabtu keempat setiap bulan.',
        false,
      );
    }
    final visibleItems = items.take(_visibleUpdateCount).toList();
    return Column(
      children: [
        ...visibleItems.map(
          (item) => _buildActionRecord(
            context,
            item,
            footer: item['lastChecked'] as String,
            buttonLabel: 'Perbarui Kondisi',
            buttonIcon: Icons.check_rounded,
            onPressed: () => openActionForm(item, false),
          ),
        ),
        _buildPagination(
          context,
          items.length,
          _visibleUpdateCount,
          'tugas',
          'Memuat tugas selanjutnya...',
          'Menampilkan seluruh ${items.length} tugas pemeriksaan',
          activeSegment == 0,
        ),
      ],
    );
  }

  Widget _buildServisList(BuildContext context) {
    if (isLoading && serviceList.isEmpty) {
      return _buildLoadingState(context, 'Memuat antrean unit bermasalah...');
    }
    if (error != null && serviceList.isEmpty) return _buildErrorState(context);
    final items = _getFilteredServiceItems();
    if (items.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.check_circle_outline_rounded,
        'Semua unit dalam kondisi prima',
        'Tidak ada komponen yang sedang membutuhkan servis.',
        true,
      );
    }
    final visibleItems = items.take(_visibleServiceCount).toList();
    return Column(
      children: [
        ...visibleItems.map(
          (item) => _buildActionRecord(
            context,
            item,
            footer: item['reporter'] as String,
            buttonLabel: 'Catat Servis',
            buttonIcon: Icons.build_rounded,
            onPressed: () => openActionForm(item, true),
          ),
        ),
        _buildPagination(
          context,
          items.length,
          _visibleServiceCount,
          'unit',
          'Memuat unit servis selanjutnya...',
          'Menampilkan seluruh ${items.length} unit butuh servis',
          activeSegment == 1,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTokens.space16),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space32),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
          const SizedBox(height: AppTokens.space12),
          Text(
            failureMessage(error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          FilledButton.icon(
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool success,
  ) {
    final theme = Theme.of(context);
    final operational = _operationalColors(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: success ? operational.onSuccess : theme.colorScheme.outline,
          ),
          const SizedBox(height: AppTokens.space12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTokens.space4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRecord(
    BuildContext context,
    Map<String, dynamic> item, {
    required String footer,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final tone = item['tone'] as String;
    final badgeBackground = tone == 'success'
        ? operational.success
        : tone == 'warning'
        ? operational.warning
        : operational.danger;
    final badgeForeground = tone == 'success'
        ? operational.onSuccess
        : tone == 'warning'
        ? operational.onWarning
        : operational.onDanger;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['code'] as String,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        item['kind'] as String,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Semantics(
                  label: 'Status inventaris: ${item['condition']}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space8,
                      vertical: AppTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(
                        AppTokens.badgeRadius,
                      ),
                    ),
                    child: Text(
                      item['condition'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              item['description'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            const Divider(height: 1),
            const SizedBox(height: AppTokens.space8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    footer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(buttonIcon),
                  label: Text(buttonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(
    BuildContext context,
    int total,
    int visible,
    String noun,
    String loadingLabel,
    String completeLabel,
    bool active,
  ) {
    final theme = Theme.of(context);
    if (_isLoadingMore && active) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppTokens.space8),
            Text(loadingLabel, style: theme.textTheme.labelLarge),
          ],
        ),
      );
    }
    if (visible < total) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            label: Text('Muat Lebih Banyak (${total - visible} $noun tersisa)'),
          ),
        ),
      );
    }
    if (total > _pageSize) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space16),
        child: Text(
          completeLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
