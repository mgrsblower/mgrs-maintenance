import 'package:flutter/material.dart';

import '../../app/gateway.dart';
import '../../design_system/components/mgrs_search_field.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';

/// Shows a bottom sheet to pick a blower component, ordered by least use.
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
    builder: (context) => ComponentPickerSheet(
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
  final TextEditingController _searchController = TextEditingController();
  var _components = <Map<String, Object?>>[];
  var _isLoading = true;
  var _hasError = false;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await widget.gateway.fetchComponents(kind: widget.kind);
      final usable = items.where((item) {
        final permission = item['boleh_dipakai']
            ?.toString()
            .trim()
            .toLowerCase();
        final condition = item['kondisi']?.toString().trim().toLowerCase();
        return permission == 'ya' && condition != 'rusak berat';
      }).toList();
      usable.sort((left, right) {
        final leftSticker = left['nomor_stiker']?.toString() ?? '';
        final rightSticker = right['nomor_stiker']?.toString() ?? '';
        final usageComparison = (widget.usageCounts[leftSticker] ?? 0)
            .compareTo(widget.usageCounts[rightSticker] ?? 0);
        return usageComparison != 0
            ? usageComparison
            : leftSticker.compareTo(rightSticker);
      });

      if (!mounted) return;
      setState(() {
        _components = usable;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Map<String, Object?>> get _visibleComponents {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return _components;
    return _components.where((component) {
      return component.values.any(
        (value) => value.toString().toLowerCase().contains(normalizedQuery),
      );
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Material(
          color: MgrsColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MgrsRadii.sheet),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              _PickerHeader(kind: widget.kind),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MgrsSpacing.lg,
                  MgrsSpacing.sm,
                  MgrsSpacing.lg,
                  MgrsSpacing.md,
                ),
                child: MgrsSearchField(
                  controller: _searchController,
                  hintText: 'Cari stiker atau detail ${widget.kind}',
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() => _query = ''),
                ),
              ),
              const Divider(height: 1, color: MgrsColors.line),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return MgrsStateView.loading(title: 'Memuat komponen ${widget.kind}...');
    }
    if (_hasError) {
      return MgrsStateView.error(
        title: 'Komponen gagal dimuat',
        message: 'Periksa koneksi internet Anda lalu coba lagi.',
        actionLabel: 'Muat data terbaru',
        onAction: _loadComponents,
      );
    }
    if (_components.isEmpty) {
      return MgrsStateView.empty(
        title: 'Belum ada ${widget.kind} siap pakai',
        message: 'Komponen yang tersedia belum memenuhi syarat penggunaan.',
        actionLabel: 'Tutup',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    final visibleComponents = _visibleComponents;
    if (visibleComponents.isEmpty) {
      return MgrsStateView.noResults(query: _query, onReset: _clearSearch);
    }

    final hasCurrentSelection = widget.currentSticker != null;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        MgrsSpacing.lg,
        MgrsSpacing.base,
        MgrsSpacing.lg,
        MgrsSpacing.xl,
      ),
      itemCount: visibleComponents.length + (hasCurrentSelection ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: MgrsSpacing.sm),
      itemBuilder: (context, index) {
        if (hasCurrentSelection && index == 0) {
          return _ClearSelectionTile(
            onTap: () => Navigator.of(context).pop(''),
          );
        }
        final componentIndex = hasCurrentSelection ? index - 1 : index;
        final component = visibleComponents[componentIndex];
        final sticker = component['nomor_stiker']?.toString() ?? '-';
        return _ComponentTile(
          sticker: sticker,
          condition: component['kondisi']?.toString() ?? 'OK',
          usageCount: widget.usageCounts[sticker] ?? 0,
          isSelected: sticker == widget.currentSticker,
          onTap: () => Navigator.of(context).pop(sticker),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: MgrsSpacing.md),
      width: 40,
      height: MgrsSpacing.xs,
      decoration: BoxDecoration(
        color: MgrsColors.line,
        borderRadius: BorderRadius.circular(MgrsRadii.pill),
      ),
    ),
  );
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      MgrsSpacing.lg,
      MgrsSpacing.sm,
      MgrsSpacing.md,
      0,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih $kind Blower',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MgrsColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MgrsSpacing.xs),
              Text(
                'Paling jarang dipakai ditampilkan lebih dahulu.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tutup pemilih komponen',
          constraints: const BoxConstraints.tightFor(
            width: MgrsSizes.minTouch,
            height: MgrsSizes.minTouch,
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: MgrsColors.muted),
        ),
      ],
    ),
  );
}

class _ClearSelectionTile extends StatelessWidget {
  const _ClearSelectionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: MgrsColors.dangerSoft,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MgrsRadii.compact),
      side: const BorderSide(color: MgrsColors.danger),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MgrsSizes.minTouch),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MgrsSpacing.base,
            vertical: MgrsSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, color: MgrsColors.danger),
              SizedBox(width: MgrsSpacing.md),
              Expanded(
                child: Text(
                  'Kosongkan pilihan',
                  style: TextStyle(
                    color: MgrsColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    required this.sticker,
    required this.condition,
    required this.usageCount,
    required this.isSelected,
    required this.onTap,
  });

  final String sticker;
  final String condition;
  final int usageCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: isSelected ? const Color(0xFFEAF5FC) : MgrsColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MgrsRadii.compact),
      side: BorderSide(
        color: isSelected ? MgrsColors.operational : MgrsColors.line,
        width: isSelected ? 2 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MgrsSizes.minTouch),
        child: Padding(
          padding: const EdgeInsets.all(MgrsSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    color: MgrsColors.operational,
                    size: 24,
                  ),
                  const SizedBox(width: MgrsSpacing.md),
                  Expanded(
                    child: Text(
                      sticker,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MgrsColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isSelected) const _SelectedBadge(),
                ],
              ),
              const SizedBox(height: MgrsSpacing.md),
              Wrap(
                spacing: MgrsSpacing.sm,
                runSpacing: MgrsSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MgrsStatusBadge(condition),
                  _UsageBadge(usageCount: usageCount),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, size: 18, color: MgrsColors.operational),
      SizedBox(width: MgrsSpacing.xs),
      Text(
        'Terpilih',
        style: TextStyle(
          color: MgrsColors.operational,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _UsageBadge extends StatelessWidget {
  const _UsageBadge({required this.usageCount});

  final int usageCount;

  @override
  Widget build(BuildContext context) {
    final color = usageCount <= 5
        ? MgrsColors.success
        : usageCount <= 15
        ? MgrsColors.warning
        : MgrsColors.muted;
    final background = usageCount <= 5
        ? MgrsColors.successSoft
        : usageCount <= 15
        ? MgrsColors.warningSoft
        : MgrsColors.canvas;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MgrsRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MgrsSpacing.md,
          vertical: MgrsSpacing.sm,
        ),
        child: Text(
          '${usageCount}x pakai',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}
