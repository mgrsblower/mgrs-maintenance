import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import 'component_picker_sheet.dart';
import 'order_model.dart';
import 'unit_allocation_model.dart';

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

class UnitAllocationCard extends StatefulWidget {
  const UnitAllocationCard({
    super.key,
    required this.gateway,
    required this.order,
    this.isEditable = true,
    this.onAllocationChanged,
  });

  final MaintenanceGateway gateway;
  final OrderanSewa order;
  final bool isEditable;
  final ValueChanged<List<AllocatedUnit>>? onAllocationChanged;

  @override
  State<UnitAllocationCard> createState() => _UnitAllocationCardState();
}

class _UnitAllocationCardState extends State<UnitAllocationCard> {
  late List<AllocatedUnit> _units;
  Map<String, int> _usageCounts = {};
  bool _isLoadingUsage = true;
  bool _isSaving = false;
  bool _isRecommending = false;

  @override
  void initState() {
    super.initState();
    _initUnits();
    _loadUsageCounts();
  }

  @override
  void didUpdateWidget(covariant UnitAllocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.catatanOrderan != widget.order.catatanOrderan ||
        oldWidget.order.jumlahUnit != widget.order.jumlahUnit) {
      _initUnits();
    }
  }

  void _initUnits() {
    final existing = List<AllocatedUnit>.from(widget.order.allocatedUnits);
    final targetCount = widget.order.jumlahUnit > 0
        ? widget.order.jumlahUnit
        : 1;
    while (existing.length < targetCount) {
      existing.add(AllocatedUnit(unitIndex: existing.length + 1));
    }
    _units = existing;
  }

  Future<void> _loadUsageCounts() async {
    try {
      final counts = await widget.gateway.fetchComponentUsageCounts();
      if (mounted) {
        setState(() {
          _usageCounts = counts;
          _isLoadingUsage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsage = false);
    }
  }

  Future<void> _saveCurrentAllocation() async {
    setState(() => _isSaving = true);
    try {
      final orderanId = widget.order.orderanId ?? widget.order.id;
      await widget.gateway.saveOrderUnitAllocation(orderanId, _units);
      widget.onAllocationChanged?.call(_units);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan unit: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickComponent(int unitIndex, String kind) async {
    if (!widget.isEditable) return;
    final current = switch (kind) {
      'Kepala' => _units[unitIndex].kepalaSticker,
      'Batang' => _units[unitIndex].batangSticker,
      'Tabung' => _units[unitIndex].tabungSticker,
      _ => null,
    };
    final selected = await showComponentPickerSheet(
      context,
      gateway: widget.gateway,
      kind: kind,
      usageCounts: _usageCounts,
      currentSticker: current,
    );
    if (selected == null) return;
    final cleanSelected = selected.isEmpty ? null : selected;
    setState(() {
      final oldUnit = _units[unitIndex];
      _units[unitIndex] = switch (kind) {
        'Kepala' => oldUnit.copyWith(
          kepalaSticker: cleanSelected,
          clearKepala: cleanSelected == null,
        ),
        'Batang' => oldUnit.copyWith(
          batangSticker: cleanSelected,
          clearBatang: cleanSelected == null,
        ),
        'Tabung' => oldUnit.copyWith(
          tabungSticker: cleanSelected,
          clearTabung: cleanSelected == null,
        ),
        _ => oldUnit,
      };
    });
    await _saveCurrentAllocation();
  }

  void _clearComponent(int unitIndex, String kind) {
    if (!widget.isEditable) return;
    setState(() {
      final oldUnit = _units[unitIndex];
      _units[unitIndex] = switch (kind) {
        'Kepala' => oldUnit.copyWith(clearKepala: true),
        'Batang' => oldUnit.copyWith(clearBatang: true),
        'Tabung' => oldUnit.copyWith(clearTabung: true),
        _ => oldUnit,
      };
    });
    _saveCurrentAllocation();
  }

  Future<void> _applyRecommendation() async {
    if (!widget.isEditable) return;
    setState(() => _isRecommending = true);
    try {
      final kepalaList = await _fetchAvailableComponents('Kepala');
      final batangList = await _fetchAvailableComponents('Batang');
      final tabungList = await _fetchAvailableComponents('Tabung');
      final assignedStickers = <String>{};
      for (final unit in _units) {
        if (unit.kepalaSticker != null) {
          assignedStickers.add(unit.kepalaSticker!);
        }
        if (unit.batangSticker != null) {
          assignedStickers.add(unit.batangSticker!);
        }
        if (unit.tabungSticker != null) {
          assignedStickers.add(unit.tabungSticker!);
        }
      }
      final newUnits = List<AllocatedUnit>.from(_units);
      for (var index = 0; index < newUnits.length; index++) {
        var unit = newUnits[index];
        if (unit.kepalaSticker == null) {
          final candidate = kepalaList.firstWhere(
            (sticker) => !assignedStickers.contains(sticker),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            unit = unit.copyWith(kepalaSticker: candidate);
          }
        }
        if (unit.batangSticker == null) {
          final candidate = batangList.firstWhere(
            (sticker) => !assignedStickers.contains(sticker),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            unit = unit.copyWith(batangSticker: candidate);
          }
        }
        if (unit.tabungSticker == null) {
          final candidate = tabungList.firstWhere(
            (sticker) => !assignedStickers.contains(sticker),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            unit = unit.copyWith(tabungSticker: candidate);
          }
        }
        newUnits[index] = unit;
      }
      setState(() => _units = newUnits);
      await _saveCurrentAllocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mengisi unit dengan komponen tersegar!'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekomendasikan unit: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecommending = false);
    }
  }

  Future<List<String>> _fetchAvailableComponents(String kind) async {
    final raw = await widget.gateway.fetchComponents(kind: kind);
    final usable = raw.where((item) {
      final allowed = item['boleh_dipakai']?.toString().trim().toLowerCase();
      final condition = item['kondisi']?.toString().trim().toLowerCase();
      return (allowed == 'ya' || allowed == 'true') &&
          condition != 'rusak berat';
    }).toList();
    usable.sort((a, b) {
      final stickerA = a['nomor_stiker']?.toString() ?? '';
      final stickerB = b['nomor_stiker']?.toString() ?? '';
      final countA = _usageCounts[stickerA] ?? 0;
      final countB = _usageCounts[stickerB] ?? 0;
      return countA != countB
          ? countA.compareTo(countB)
          : stickerA.compareTo(stickerB);
    });
    return usable
        .map((item) => item['nomor_stiker']?.toString().trim() ?? '')
        .where((sticker) => sticker.isNotEmpty)
        .toList();
  }

  Future<void> _showScanDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan Barcode Komponen'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppTokens.controlRadius),
                ),
                child: SizedBox(
                  height: 180,
                  child: MobileScanner(
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        final value = barcode.rawValue?.trim().toUpperCase();
                        if (value != null && value.isNotEmpty) {
                          Navigator.of(dialogContext).pop(value);
                          return;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Atau ketik kode stiker:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              TextField(
                controller: textController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Contoh: K-01, B-02, T-03',
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop(value.trim().toUpperCase());
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(
                  dialogContext,
                ).pop(textController.text.trim().toUpperCase());
              }
            },
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (result == null || result.isEmpty) return;
    _assignScannedCode(result);
  }

  void _assignScannedCode(String code) {
    final kind = code.startsWith('K')
        ? 'Kepala'
        : code.startsWith('B')
        ? 'Batang'
        : code.startsWith('T')
        ? 'Tabung'
        : null;
    if (kind == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kode "$code" tidak dikenali. Format harus K-xx, B-xx, atau T-xx.',
          ),
        ),
      );
      return;
    }
    var targetIndex = -1;
    for (var index = 0; index < _units.length; index++) {
      final value = switch (kind) {
        'Kepala' => _units[index].kepalaSticker,
        'Batang' => _units[index].batangSticker,
        'Tabung' => _units[index].tabungSticker,
        _ => null,
      };
      if (value == null || value.isEmpty) {
        targetIndex = index;
        break;
      }
    }
    if (targetIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua unit sudah memiliki komponen $kind ($code)'),
        ),
      );
      return;
    }
    setState(() {
      final oldUnit = _units[targetIndex];
      _units[targetIndex] = switch (kind) {
        'Kepala' => oldUnit.copyWith(kepalaSticker: code),
        'Batang' => oldUnit.copyWith(batangSticker: code),
        'Tabung' => oldUnit.copyWith(tabungSticker: code),
        _ => oldUnit,
      };
    });
    _saveCurrentAllocation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$kind Unit ${targetIndex + 1} diatur ke $code')),
    );
  }

  ({Color surface, Color ink}) _usageTone(BuildContext context, int count) {
    final operational = _operationalColors(context);
    final colors = Theme.of(context).colorScheme;
    if (count <= 5) {
      return (surface: operational.success, ink: operational.onSuccess);
    }
    if (count <= 15) {
      return (surface: operational.warning, ink: operational.onWarning);
    }
    return (surface: colors.surfaceContainer, ink: colors.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final completeUnits = _units.where((unit) => unit.isComplete).length;
    final totalUnits = _units.length;
    final complete = completeUnits == totalUnits && totalUnits > 0;
    final partial = completeUnits > 0 || _units.any((unit) => !unit.isEmpty);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Alokasi Unit Blower',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Chip(label: Text('Opsional')),
                        ],
                      ),
                      Text(
                        '$completeUnits dari $totalUnits unit lengkap',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: complete
                              ? operational.onSuccess
                              : partial
                              ? operational.onWarning
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            if (widget.isEditable) ...[
              const SizedBox(height: AppTokens.space12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRecommending ? null : _applyRecommendation,
                      icon: _isRecommending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Rekomendasi Tersegar'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showScanDialog,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan Barcode'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.space12),
            const Divider(),
            const SizedBox(height: AppTokens.space12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _units.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTokens.space12),
              itemBuilder: (context, index) =>
                  _buildUnitItem(context, index, _units[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitItem(BuildContext context, int index, AllocatedUnit unit) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final tone = unit.isComplete
        ? (surface: operational.success, ink: operational.onSuccess)
        : !unit.isEmpty
        ? (surface: operational.warning, ink: operational.onWarning)
        : (surface: colors.surfaceContainer, ink: colors.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppTokens.controlRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Unit ${index + 1}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Chip(
                label: Text(
                  unit.isComplete
                      ? 'Lengkap'
                      : unit.isEmpty
                      ? 'Kosong'
                      : 'Sebagian',
                ),
                backgroundColor: tone.surface,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: tone.ink,
                ),
                side: BorderSide(color: tone.ink),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space8),
          Row(
            children: [
              Expanded(
                child: _buildComponentSlot(
                  context,
                  index,
                  'Kepala',
                  unit.kepalaSticker,
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: _buildComponentSlot(
                  context,
                  index,
                  'Batang',
                  unit.batangSticker,
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: _buildComponentSlot(
                  context,
                  index,
                  'Tabung',
                  unit.tabungSticker,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSlot(
    BuildContext context,
    int unitIndex,
    String kind,
    String? sticker,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = sticker == null ? null : (_usageCounts[sticker] ?? 0);
    final assigned = sticker?.isNotEmpty == true;
    final tone = count == null ? null : _usageTone(context, count);
    return InkWell(
      onTap: widget.isEditable ? () => _pickComponent(unitIndex, kind) : null,
      borderRadius: const BorderRadius.all(
        Radius.circular(AppTokens.badgeRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(AppTokens.space8),
        decoration: BoxDecoration(
          color: assigned ? colors.surface : colors.surfaceContainer,
          border: Border.all(
            color: assigned ? colors.outline : colors.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(AppTokens.badgeRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(kind, style: theme.textTheme.labelMedium),
            if (assigned) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sticker!,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isEditable)
                    IconButton(
                      tooltip: 'Kosongkan $kind',
                      onPressed: () => _clearComponent(unitIndex, kind),
                      icon: const Icon(Icons.close),
                      constraints: const BoxConstraints(
                        minWidth: AppTokens.minTouchTarget,
                        minHeight: AppTokens.minTouchTarget,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              if (count != null && !_isLoadingUsage)
                Chip(
                  label: Text('${count}x pakai'),
                  backgroundColor: tone!.surface,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: tone.ink,
                  ),
                  side: BorderSide(color: tone.ink),
                ),
            ] else
              Row(
                children: [
                  if (widget.isEditable) ...[
                    Icon(
                      Icons.add,
                      size: AppTokens.space16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppTokens.space4),
                    Text(
                      'Pilih',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ] else
                    Text('-', style: theme.textTheme.labelMedium),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
