import 'package:flutter/material.dart';
import '../../app/gateway.dart';

/// Shows a bottom sheet to pick a blower component (Kepala, Batang, or Tabung)
/// sorted by wear-and-tear (usage counts ascending).
Future<String?> showComponentPickerSheet(
  BuildContext context, {
  required MaintenanceGateway gateway,
  required String kind,
  required Map<String, int> usageCounts,
  String? currentSticker,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ComponentPickerSheet(
      gateway: gateway,
      kind: kind,
      usageCounts: usageCounts,
      currentSticker: currentSticker,
    ),
  );
}

class ComponentPickerSheet extends StatefulWidget {
  const ComponentPickerSheet({
    super.key,
    required this.gateway,
    required this.kind,
    required this.usageCounts,
    this.currentSticker,
  });

  final MaintenanceGateway gateway;
  final String kind;
  final Map<String, int> usageCounts;
  final String? currentSticker;

  @override
  State<ComponentPickerSheet> createState() => _ComponentPickerSheetState();
}

class _ComponentPickerSheetState extends State<ComponentPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, Object?>> _allComponents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.gateway.fetchComponents(kind: widget.kind);
      // Filter usable components: boleh_dipakai == 'Ya' and not 'Rusak Berat'
      final filtered = items.where((item) {
        final boleh = item['boleh_dipakai']?.toString().trim().toLowerCase();
        final kondisi = item['kondisi']?.toString().trim().toLowerCase();
        final isAllowed = boleh == 'ya' || boleh == 'true';
        final isNotSevere = kondisi != 'rusak berat';
        return isAllowed && isNotSevere;
      }).toList();

      // Sort by usage count ascending, then sticker name
      filtered.sort((a, b) {
        final stickerA = a['nomor_stiker']?.toString() ?? '';
        final stickerB = b['nomor_stiker']?.toString() ?? '';
        final countA = widget.usageCounts[stickerA] ?? 0;
        final countB = widget.usageCounts[stickerB] ?? 0;

        if (countA != countB) {
          return countA.compareTo(countB);
        }
        return stickerA.compareTo(stickerB);
      });

      if (mounted) {
        setState(() {
          _allComponents = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _badgeBgColor(int count) {
    if (count <= 5) return const Color(0xFFDCFCE7); // Light green
    if (count <= 15) return const Color(0xFFFEF3C7); // Light amber
    return const Color(0xFFF1F5F9); // Slate grey
  }

  Color _badgeTextColor(int count) {
    if (count <= 5) return const Color(0xFF166534); // Dark green
    if (count <= 15) return const Color(0xFF92400E); // Dark amber
    return const Color(0xFF475569); // Slate dark
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedItems = _allComponents.where((item) {
      if (_searchQuery.isEmpty) return true;
      final sticker = (item['nomor_stiker']?.toString() ?? '').toLowerCase();
      return sticker.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih ${widget.kind} Blower',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Urutan atas adalah unit tersegar / paling jarang dipakai',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari stiker ${widget.kind} (contoh: 01)...',
                prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus pencarian',
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const Divider(height: 16),
          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gagal memuat komponen: $_error',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadComponents,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : displayedItems.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada ${widget.kind} dengan kode "$_searchQuery"'
                                  : 'Belum ada data ${widget.kind} yang siap pakai',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: displayedItems.length + (widget.currentSticker != null ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              // Optional "Kosongkan Pilihan" at top if currently selected
                              if (widget.currentSticker != null && index == 0) {
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                                  ),
                                  leading: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                                  title: Text(
                                    'Kosongkan Pilihan',
                                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                                  ),
                                  onTap: () => Navigator.of(context).pop(''),
                                );
                              }

                              final itemIndex = widget.currentSticker != null ? index - 1 : index;
                              final item = displayedItems[itemIndex];
                              final sticker = item['nomor_stiker']?.toString() ?? '-';
                              final kondisi = item['kondisi']?.toString() ?? 'OK';
                              final count = widget.usageCounts[sticker] ?? 0;
                              final isSelected = sticker == widget.currentSticker;

                              return InkWell(
                                onTap: () => Navigator.of(context).pop(sticker),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                              : theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.qr_code_2,
                                          size: 20,
                                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sticker,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              'Kondisi: $kondisi',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Wear-and-tear badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _badgeBgColor(count),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (count <= 5)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: Icon(Icons.eco, size: 12, color: Color(0xFF166534)),
                                              ),
                                            Text(
                                              '${count}x pakai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _badgeTextColor(count),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
