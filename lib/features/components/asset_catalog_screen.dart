import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
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
      Map<String, dynamic> a, Map<String, dynamic> b) {
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
    final matchesA =
        regex.allMatches(a.trim()).map((m) => m.group(0)!).toList();
    final matchesB =
        regex.allMatches(b.trim()).map((m) => m.group(0)!).toList();

    final length =
        matchesA.length < matchesB.length ? matchesA.length : matchesB.length;
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
      final matchesSearch = query.isEmpty ||
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
      final rows =
          await widget.gateway.fetchComponents(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        final mapped = rows.map((r) {
          final cond = (r['kondisi'] ?? r['condition'] ?? 'OK').toString();
          final isOk = cond == 'OK' || cond == 'Layak Pakai';
          final isService = cond == 'Service' ||
              cond == 'Rusak Berat' ||
              cond == 'Gangguan Fungsi';
          final color = isOk
              ? const Color(0xFF10B981)
              : (isService
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B));
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
            'description': (r['keterangan'] ??
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
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => loadComponents(forceRefresh: true),
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
                      _buildSearchBar(context),
                      const SizedBox(height: 14),
                      _buildCategoryChips(context),
                      const SizedBox(height: 16),
                      _buildComponentList(context, filtered),
                      const SizedBox(height: 110), // Spacing for floating navbar
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
              currentIndex: 1,
              onNavigateToTab: widget.onNavigateToTab,
              onOpenScanner: widget.onOpenScanner,
            )
          : null,
    );
  }

  // Header: "Komponen MGRS" + "{count} item terdaftar • Kepala, Batang, Tabung" + Filter Icon button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Komponen MGRS',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${components.length} item terdaftar • Kepala, Batang, Tabung',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
                Icons.filter_list_rounded,
                color: Color(0xFF334155),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() => _visibleCount = _pageSize),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Cari Kode...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
    );
  }

  // Category Chips: [Semua], [Kepala], [Batang], [Tabung]
  Widget _buildCategoryChips(BuildContext context) {
    final categories = ['Semua', 'Kepala', 'Batang', 'Tabung'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: () => setState(() {
                activeCategory = cat;
                _visibleCount = _pageSize;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // List of Component Cards
  Widget _buildComponentList(BuildContext context, List<Map<String, dynamic>> items) {
    if (isLoading && components.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF147CC1)),
              SizedBox(height: 14),
              Text(
                'Memuat katalog aset...',
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

    if (error != null && components.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
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
              onPressed: loadComponents,
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

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Tidak ada komponen ditemukan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Coba ubah kata kunci pencarian atau kategori filter.',
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
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
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
                        Text(
                          item['code'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: item['conditionColor'] as Color,
                            borderRadius: BorderRadius.circular(20),
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
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['description'] as String,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item['inspector'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_isLoadingMore)
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
                  'Memuat komponen selanjutnya...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else if (_visibleCount < items.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: PressableScale(
                onTap: _loadMore,
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
                        'Muat Lebih Banyak (${items.length - _visibleCount} tersisa)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
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
                'Menampilkan seluruh ${items.length} komponen',
                style: const TextStyle(
                  fontFamily: 'Inter',
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
