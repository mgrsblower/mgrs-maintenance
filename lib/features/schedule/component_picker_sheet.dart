import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';

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

/// Shows a bottom sheet to pick a blower component sorted by usage count.
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
      final filtered = items.where((item) {
        final usable = item['boleh_dipakai']?.toString().trim().toLowerCase();
        final condition = item['kondisi']?.toString().trim().toLowerCase();
        return (usable == 'ya' || usable == 'true') && condition != 'rusak berat';
      }).toList();
      filtered.sort((a, b) {
        final stickerA = a['nomor_stiker']?.toString() ?? '';
        final stickerB = b['nomor_stiker']?.toString() ?? '';
        final countA = widget.usageCounts[stickerA] ?? 0;
        final countB = widget.usageCounts[stickerB] ?? 0;
        return countA != countB ? countA.compareTo(countB) : stickerA.compareTo(stickerB);
      });
      if (mounted) {
        setState(() {
          _allComponents = filtered;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  ({Color surface, Color ink}) _usageTone(BuildContext context, int count) {
    final operational = _operationalColors(context);
    final colors = Theme.of(context).colorScheme;
    if (count <= 5) return (surface: operational.success, ink: operational.onSuccess);
    if (count <= 15) return (surface: operational.warning, ink: operational.onWarning);
    return (surface: colors.surfaceContainer, ink: colors.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayedItems = _allComponents.where((item) {
      if (_searchQuery.isEmpty) return true;
      return (item['nomor_stiker']?.toString() ?? '')
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space16,
                AppTokens.space8,
                AppTokens.space16,
                AppTokens.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pilih ${widget.kind} Blower', style: theme.textTheme.titleLarge),
                        Text(
                          'Urutan atas adalah unit tersegar / paling jarang dipakai',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari stiker ${widget.kind} (contoh: 01)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorView(context)
                      : displayedItems.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada ${widget.kind} dengan kode "$_searchQuery"'
                                    : 'Belum ada data ${widget.kind} yang siap pakai',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space16,
                                vertical: AppTokens.space8,
                              ),
                              itemCount: displayedItems.length +
                                  (widget.currentSticker != null ? 1 : 0),
                              separatorBuilder: (_, _) => const SizedBox(height: AppTokens.space8),
                              itemBuilder: (context, index) {
                                if (widget.currentSticker != null && index == 0) {
                                  return OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).pop(''),
                                    icon: Icon(Icons.remove_circle_outline, color: colors.error),
                                    label: const Text('Kosongkan Pilihan'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.error,
                                      side: BorderSide(color: colors.error),
                                      alignment: Alignment.centerLeft,
                                    ),
                                  );
                                }
                                final item = displayedItems[
                                  widget.currentSticker != null ? index - 1 : index
                                ];
                                final sticker = item['nomor_stiker']?.toString() ?? '-';
                                final condition = item['kondisi']?.toString() ?? 'OK';
                                final count = widget.usageCounts[sticker] ?? 0;
                                final selected = sticker == widget.currentSticker;
                                final tone = _usageTone(context, count);
                                return Material(
                                  color: colors.surface,
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).pop(sticker),
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
                                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
                                      decoration: BoxDecoration(
                                        color: selected ? colors.primaryContainer : colors.surface,
                                        border: Border.all(
                                          color: selected ? colors.primary : colors.outline,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(AppTokens.controlRadius),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_2, color: selected ? colors.primary : colors.onSurfaceVariant),
                                          const SizedBox(width: AppTokens.space12),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(sticker, style: theme.textTheme.titleMedium),
                                                Text('Kondisi: $condition', style: theme.textTheme.labelMedium),
                                              ],
                                            ),
                                          ),
                                          Chip(
                                            label: Text('${count}x pakai'),
                                            avatar: count <= 5 ? Icon(Icons.eco, size: AppTokens.space16, color: tone.ink) : null,
                                            backgroundColor: tone.surface,
                                            labelStyle: theme.textTheme.labelMedium?.copyWith(color: tone.ink),
                                            side: BorderSide(color: tone.ink),
                                          ),
                                          if (selected) ...[
                                            const SizedBox(width: AppTokens.space8),
                                            Icon(Icons.check_circle, color: colors.primary),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gagal memuat komponen: $_error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
            const SizedBox(height: AppTokens.space12),
            OutlinedButton(onPressed: _loadComponents, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
