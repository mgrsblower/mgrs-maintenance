import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/gateway.dart';
import 'component_picker_sheet.dart';
import 'order_model.dart';
import 'unit_allocation_model.dart';

/// Card to manage and view optional unit allocations (Kepala + Batang + Tabung)
/// for an order, with wear-and-tear usage tracking to balance equipment usage.
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
    final targetCount = widget.order.jumlahUnit > 0 ? widget.order.jumlahUnit : 1;

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
      if (mounted) {
        setState(() => _isLoadingUsage = false);
      }
    }
  }

  Future<void> _saveCurrentAllocation() async {
    setState(() => _isSaving = true);
    try {
      final orderanId = widget.order.orderanId ?? widget.order.id;
      await widget.gateway.saveOrderUnitAllocation(
        orderanId,
        _units,
      );
      widget.onAllocationChanged?.call(_units);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan unit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
        'Kepala' => oldUnit.copyWith(kepalaSticker: cleanSelected, clearKepala: cleanSelected == null),
        'Batang' => oldUnit.copyWith(batangSticker: cleanSelected, clearBatang: cleanSelected == null),
        'Tabung' => oldUnit.copyWith(tabungSticker: cleanSelected, clearTabung: cleanSelected == null),
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

      // Set of stickers already assigned in this order
      final assignedStickers = <String>{};
      for (final u in _units) {
        if (u.kepalaSticker != null) assignedStickers.add(u.kepalaSticker!);
        if (u.batangSticker != null) assignedStickers.add(u.batangSticker!);
        if (u.tabungSticker != null) assignedStickers.add(u.tabungSticker!);
      }

      final newUnits = List<AllocatedUnit>.from(_units);

      for (var i = 0; i < newUnits.length; i++) {
        var u = newUnits[i];

        if (u.kepalaSticker == null) {
          final candidate = kepalaList.firstWhere(
            (s) => !assignedStickers.contains(s),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            u = u.copyWith(kepalaSticker: candidate);
          }
        }

        if (u.batangSticker == null) {
          final candidate = batangList.firstWhere(
            (s) => !assignedStickers.contains(s),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            u = u.copyWith(batangSticker: candidate);
          }
        }

        if (u.tabungSticker == null) {
          final candidate = tabungList.firstWhere(
            (s) => !assignedStickers.contains(s),
            orElse: () => '',
          );
          if (candidate.isNotEmpty) {
            assignedStickers.add(candidate);
            u = u.copyWith(tabungSticker: candidate);
          }
        }

        newUnits[i] = u;
      }

      setState(() {
        _units = newUnits;
      });

      await _saveCurrentAllocation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Berhasil mengisi unit dengan komponen tersegar!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekomendasikan unit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecommending = false);
      }
    }
  }

  Future<List<String>> _fetchAvailableComponents(String kind) async {
    final raw = await widget.gateway.fetchComponents(kind: kind);
    final usable = raw.where((item) {
      final boleh = item['boleh_dipakai']?.toString().trim().toLowerCase();
      final kondisi = item['kondisi']?.toString().trim().toLowerCase();
      return (boleh == 'ya' || boleh == 'true') && kondisi != 'rusak berat';
    }).toList();

    usable.sort((a, b) {
      final stikerA = a['nomor_stiker']?.toString() ?? '';
      final stikerB = b['nomor_stiker']?.toString() ?? '';
      final countA = _usageCounts[stikerA] ?? 0;
      final countB = _usageCounts[stikerB] ?? 0;
      if (countA != countB) return countA.compareTo(countB);
      return stikerA.compareTo(stikerB);
    });

    return usable
        .map((item) => item['nomor_stiker']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _showScanDialog() async {
    final textCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Scan Barcode Komponen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final val = barcode.rawValue?.trim().toUpperCase();
                        if (val != null && val.isNotEmpty) {
                          Navigator.of(dialogCtx).pop(val);
                          return;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Atau ketik kode stiker:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              TextField(
                controller: textCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Contoh: K-01, B-02, T-03',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    Navigator.of(dialogCtx).pop(val.trim().toUpperCase());
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                Navigator.of(dialogCtx).pop(textCtrl.text.trim().toUpperCase());
              }
            },
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    _assignScannedCode(result);
  }

  void _assignScannedCode(String code) {
    String? kind;
    if (code.startsWith('K')) {
      kind = 'Kepala';
    } else if (code.startsWith('B')) {
      kind = 'Batang';
    } else if (code.startsWith('T')) {
      kind = 'Tabung';
    }

    if (kind == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode "$code" tidak dikenali. Format harus K-xx, B-xx, atau T-xx.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // Find first unit where this slot is empty
    int targetIndex = -1;
    for (var i = 0; i < _units.length; i++) {
      final val = switch (kind) {
        'Kepala' => _units[i].kepalaSticker,
        'Batang' => _units[i].batangSticker,
        'Tabung' => _units[i].tabungSticker,
        _ => null,
      };
      if (val == null || val.isEmpty) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua unit sudah memiliki komponen $kind ($code)'),
          backgroundColor: Colors.orange.shade800,
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
      SnackBar(
        content: Text('✅ $kind Unit ${targetIndex + 1} diatur ke $code'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Color _badgeBgColor(int count) {
    if (count <= 5) return const Color(0xFFDCFCE7);
    if (count <= 15) return const Color(0xFFFEF3C7);
    return const Color(0xFFF1F5F9);
  }

  Color _badgeTextColor(int count) {
    if (count <= 5) return const Color(0xFF166534);
    if (count <= 15) return const Color(0xFF92400E);
    return const Color(0xFF475569);
  }

  @override
  Widget build(BuildContext context) {
    final completeUnits = _units.where((u) => u.isComplete).length;
    final totalUnits = _units.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Alokasi Unit Blower',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Opsional',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completeUnits dari $totalUnits unit lengkap',
                      style: TextStyle(
                        fontSize: 12,
                        color: completeUnits == totalUnits && totalUnits > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                        fontWeight: completeUnits == totalUnits && totalUnits > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          // Action buttons for editable users
          if (widget.isEditable) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRecommending ? null : _applyRecommendation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isRecommending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF16A34A)),
                    label: const Text(
                      'Rekomendasi Tersegar',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showScanDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text(
                    'Scan Barcode',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Units List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _units.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final unit = _units[index];
              return _buildUnitItem(index, unit);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitItem(int index, AllocatedUnit unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unit title & completion status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (unit.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 11, color: Color(0xFF166534)),
                      SizedBox(width: 3),
                      Text(
                        'Lengkap',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!unit.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Sebagian',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 3 Component slots (Kepala, Batang, Tabung)
          Row(
            children: [
              Expanded(
                child: _buildComponentSlot(
                  unitIndex: index,
                  kind: 'Kepala',
                  sticker: unit.kepalaSticker,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildComponentSlot(
                  unitIndex: index,
                  kind: 'Batang',
                  sticker: unit.batangSticker,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildComponentSlot(
                  unitIndex: index,
                  kind: 'Tabung',
                  sticker: unit.tabungSticker,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSlot({
    required int unitIndex,
    required String kind,
    required String? sticker,
  }) {
    final count = sticker != null ? (_usageCounts[sticker] ?? 0) : null;
    final isAssigned = sticker != null && sticker.isNotEmpty;

    return InkWell(
      onTap: widget.isEditable ? () => _pickComponent(unitIndex, kind) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: isAssigned ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAssigned ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Kind label
            Text(
              kind,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),

            // Sticker code or placeholder
            if (isAssigned) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sticker,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isEditable)
                    GestureDetector(
                      onTap: () => _clearComponent(unitIndex, kind),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 13, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
              if (count != null && !_isLoadingUsage) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _badgeBgColor(count),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${count}x pakai',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _badgeTextColor(count),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
              ],
            ] else ...[
              Row(
                children: [
                  if (widget.isEditable) ...[
                    const Icon(Icons.add, size: 12, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 2),
                    const Text(
                      'Pilih',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '-',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
