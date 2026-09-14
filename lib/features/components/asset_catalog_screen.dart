import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_search_field.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import '../../shared/async_state_view.dart' show conditionDisplayLabel;
import '../../shared/bottom_nav_bar.dart';
import '../../shared/pressable.dart';
import '../components/component_detail_screen.dart';

class AssetCatalogScreen extends StatefulWidget {
  const AssetCatalogScreen({
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
  State<AssetCatalogScreen> createState() => _AssetCatalogScreenState();
}

class _AssetCatalogScreenState extends State<AssetCatalogScreen>
    with AutomaticKeepAliveClientMixin {
  String activeCategory = 'Semua';
  final searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  static const int _pageSize = 10;
  int _visibleCount = 10;
  bool _isLoadingMore = false;
  bool isLoading = false;
  Object? error;
  List<Map<String, dynamic>> components = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    loadComponents();
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
    final total = _getFilteredItems().length;
    if (_visibleCount < total) {
      setState(() => _isLoadingMore = true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _visibleCount = math.min(_visibleCount + _pageSize, total);
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  static int _componentSortWeight(Map<String, dynamic> c) {
    final kind = (c['kind'] ?? '').toString().toLowerCase();
    final code = (c['code'] ?? '').toString().toUpperCase();
    if (kind.contains('kepala') ||
        code.startsWith('K-') ||
        code.startsWith('KPL') ||
        code.startsWith('K')) {
      return 1;
    }
    if (kind.contains('batang') ||
        code.startsWith('B-') ||
        code.startsWith('BTG') ||
        code.startsWith('B')) {
      return 2;
    }
    if (kind.contains('tabung') ||
        code.startsWith('T-') ||
        code.startsWith('TBG') ||
        code.startsWith('T')) {
      return 3;
    }
    return 4;
  }

  static int _compareComponents(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final weightA = _componentSortWeight(a);
    final weightB = _componentSortWeight(b);
    if (weightA != weightB) {
      return weightA.compareTo(weightB);
    }
    final codeA = (a['code'] ?? '').toString();
    final codeB = (b['code'] ?? '').toString();
    return _compareCode(codeA, codeB);
  }

  static int _compareCode(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final matchesA = regex
        .allMatches(a.trim())
        .map((m) => m.group(0)!)
        .toList();
    final matchesB = regex
        .allMatches(b.trim())
        .map((m) => m.group(0)!)
        .toList();

    final length = matchesA.length < matchesB.length
        ? matchesA.length
        : matchesB.length;
    for (int i = 0; i < length; i++) {
      final tokenA = matchesA[i];
      final tokenB = matchesB[i];

      final numA = int.tryParse(tokenA);
      final numB = int.tryParse(tokenB);

      if (numA != null && numB != null) {
        final diff = numA.compareTo(numB);
        if (diff != 0) return diff;
      } else {
        final diff = tokenA.toLowerCase().compareTo(tokenB.toLowerCase());
        if (diff != 0) return diff;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    final filtered = components.where((c) {
      final matchesCat =
          activeCategory == 'Semua' || c['kind'] == activeCategory;
      final query = searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          (c['code'] as String).toLowerCase().contains(query) ||
          (c['description'] as String).toLowerCase().contains(query);
      return matchesCat && matchesSearch;
    }).toList();
    filtered.sort(_compareComponents);
    return filtered;
  }

  Future<void> loadComponents({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final rows = await widget.gateway.fetchComponents(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        final mapped = rows.map((r) {
          final cond = (r['kondisi'] ?? r['condition'] ?? 'OK').toString();
          final isOk = cond == 'OK' || cond == 'Layak Pakai';
          final isService =
              cond == 'Service' ||
              cond == 'Rusak Berat' ||
              cond == 'Gangguan Fungsi';
          final color = isOk
              ? const Color(0xFF10B981)
              : (isService ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
          final condLabel = conditionDisplayLabel(cond);
          final updated = (r['updated_at'] ?? '').toString();
          final dateStr = updated.length >= 10
              ? updated.substring(0, 10)
              : 'Tersedia';

          return {
            'id': (r['id'] ?? '').toString(),
            'code': (r['nomor_stiker'] ?? r['code'] ?? '').toString(),
            'kind': (r['jenis_komponen'] ?? r['kind'] ?? 'Kepala').toString(),
            'condition': condLabel,
            'conditionColor': color,
            'description':
                (r['keterangan'] ??
                        r['note'] ??
                        'Komponen operasional terdata di sistem MGRS.')
                    .toString(),
            'inspector': dateStr,
          };
        }).toList();
        mapped.sort(_compareComponents);
        components = mapped;
        _visibleCount = _pageSize;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _getFilteredItems();

    return Scaffold(
      backgroundColor: MgrsColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => loadComponents(forceRefresh: true),
          color: MgrsColors.operational,
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MgrsSpacing.lg,
                  MgrsSpacing.md,
                  MgrsSpacing.lg,
                  MgrsSpacing.xl,
                ),
                sliver: SliverList.list(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: MgrsSpacing.base),
                    _buildSearchBar(context),
                    const SizedBox(height: MgrsSpacing.md),
                    _buildCategoryChips(context),
                    const SizedBox(height: MgrsSpacing.lg),
                    _buildComponentList(context, filtered),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNavBar(
              currentIndex: 1,
              onNavigateToTab: widget.onNavigateToTab,
              onOpenScanner: widget.onOpenScanner,
            )
          : null,
    );
  }

  // Header: "Komponen MGRS" + "{count} item terdaftar • Kepala, Batang, Tabung" + Filter Icon button
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komponen MGRS',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: MgrsColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: MgrsSpacing.xs),
        Text(
          '${components.length} item terdaftar · Kepala, Batang, Tabung',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar(BuildContext context) {
    return MgrsSearchField(
      controller: searchController,
      hintText: 'Cari kode atau keterangan',
      onChanged: (_) => setState(() => _visibleCount = _pageSize),
    );
  }

  // Category Chips: [Semua], [Kepala], [Batang], [Tabung]
  Widget _buildCategoryChips(BuildContext context) {
    const categories = ['Semua', 'Kepala', 'Batang', 'Tabung'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories
            .map((cat) {
              final isSelected = activeCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: MgrsSpacing.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: MgrsSizes.minTouch,
                    minHeight: MgrsSizes.minTouch,
                  ),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      activeCategory = cat;
                      _visibleCount = _pageSize;
                    }),
                    showCheckmark: false,
                    selectedColor: MgrsColors.ink,
                    backgroundColor: MgrsColors.surface,
                    side: const BorderSide(color: MgrsColors.line),
                    shape: const StadiumBorder(),
                    labelStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          color: isSelected
                              ? MgrsColors.surface
                              : MgrsColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  // List of Component Cards
  Widget _buildComponentList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    if (isLoading && components.isEmpty) {
      return const MgrsStateView.loading(title: 'Memuat katalog aset...');
    }

    if (error != null && components.isEmpty) {
      return MgrsStateView.error(
        title: 'Katalog aset gagal dimuat',
        message: 'Periksa koneksi, lalu muat data terbaru.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadComponents(forceRefresh: true),
      );
    }

    if (items.isEmpty) {
      final query = searchController.text.trim();
      if (components.isNotEmpty &&
          (query.isNotEmpty || activeCategory != 'Semua')) {
        final criteria = [
          if (query.isNotEmpty) query,
          if (activeCategory != 'Semua') 'kategori $activeCategory',
        ].join(' pada ');
        return MgrsStateView.noResults(
          query: criteria,
          onReset: () => setState(() {
            searchController.clear();
            activeCategory = 'Semua';
            _visibleCount = _pageSize;
          }),
        );
      }
      return MgrsStateView.empty(
        title: 'Database komponen masih kosong',
        message: 'Belum ada komponen yang tersimpan di MGRS.',
        actionLabel: 'Muat data terbaru',
        onAction: () => loadComponents(forceRefresh: true),
      );
    }

    final visibleItems = items.take(_visibleCount).toList();

    return Column(
      children: [
        ...visibleItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PressableScale(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ComponentDetailScreen(
                      gateway: widget.gateway,
                      id: item['id'] as String,
                    ),
                  ),
                );
              },
              child: Semantics(
                button: true,
                label:
                    'Buka komponen ${item['code']}, status ${item['condition']}',
                child: Container(
                  padding: const EdgeInsets.all(MgrsSpacing.base),
                  decoration: BoxDecoration(
                    color: MgrsColors.surface,
                    borderRadius: BorderRadius.circular(MgrsRadii.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final identity = Text(
                            item['code'] as String,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: MgrsColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          );
                          final badge = MgrsStatusBadge(
                            item['condition'] as String,
                          );
                          if (constraints.maxWidth < 300) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                identity,
                                const SizedBox(height: MgrsSpacing.sm),
                                badge,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: identity),
                              const SizedBox(width: MgrsSpacing.md),
                              Flexible(child: badge),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: MgrsSpacing.md),
                      Text(
                        item['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MgrsColors.muted,
                        ),
                      ),
                      const SizedBox(height: MgrsSpacing.md),
                      const Divider(height: 1, color: MgrsColors.line),
                      const SizedBox(height: MgrsSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 18,
                            color: MgrsColors.muted,
                          ),
                          const SizedBox(width: MgrsSpacing.sm),
                          Expanded(
                            child: Text(
                              item['inspector'] as String,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: MgrsColors.muted),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: MgrsColors.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: MgrsSpacing.base),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (_visibleCount < items.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.md),
            child: Center(
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                label: Text(
                  'Muat lebih banyak (${items.length - _visibleCount} tersisa)',
                ),
              ),
            ),
          )
        else if (items.length > _pageSize)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MgrsSpacing.base),
            child: Text(
              'Menampilkan seluruh ${items.length} komponen',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
            ),
          ),
      ],
    );
  }
}
