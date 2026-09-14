import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import 'component_picker_sheet.dart';
import 'order_model.dart';
import 'unit_allocation_model.dart';

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
    final targetCount =
        widget.order.jumlahUnit > 0 ? widget.order.jumlahUnit : 1;

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
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentAllocation() async {
    try {
      final orderanId = widget.order.orderanId ?? widget.order.id;
      await widget.gateway.saveOrderUnitAllocation(
        orderanId,
        _units,
      );
      widget.onAllocationChanged?.call(_units);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alokasi komponen belum dapat disimpan.'),
            backgroundColor: MgrsColors.danger,
          ),
        );
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
            content: Text('Komponen tersegar berhasil dialokasikan!'),
            backgroundColor: MgrsColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal merekomendasikan unit.'),
            backgroundColor: MgrsColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
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
    String? dialogError;
    bool isProcessing = false;

    await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> processCode(String rawCode) async {
            final normalizedCode = rawCode.trim().toUpperCase();
            if (normalizedCode.isEmpty) return;

            textCtrl.clear();
            setDialogState(() {
              isProcessing = true;
              dialogError = null;
            });

            String? expectedKind;
            if (normalizedCode.startsWith('K')) {
              expectedKind = 'Kepala';
            } else if (normalizedCode.startsWith('B')) {
              expectedKind = 'Batang';
            } else if (normalizedCode.startsWith('T')) {
              expectedKind = 'Tabung';
            }

            if (expectedKind == null) {
              setDialogState(() {
                isProcessing = false;
                dialogError =
                    'Kode "$rawCode" tidak dikenali. Format stiker harus diawali K-, B-, atau T-.';
              });
              return;
            }

            try {
              final searchResults = await widget.gateway.fetchComponents(
                query: normalizedCode,
                forceRefresh: true,
              );

              if (searchResults.isEmpty) {
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Komponen $normalizedCode tidak ditemukan atau tidak layak pakai.';
                });
                return;
              }

              final exactMatch =
                  searchResults.cast<Map<String, Object?>?>().firstWhere(
                        (c) =>
                            c?['nomor_stiker']
                                ?.toString()
                                .trim()
                                .toUpperCase() ==
                            normalizedCode,
                        orElse: () => null,
                      );

              if (exactMatch == null) {
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Komponen hasil pencarian tidak cocok dengan kode stiker $normalizedCode.';
                });
                return;
              }

              final dbKind =
                  exactMatch['jenis_komponen']?.toString().trim() ?? '';
              if (dbKind != expectedKind) {
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Komponen $normalizedCode terdaftar sebagai $dbKind, bukan $expectedKind.';
                });
                return;
              }

              final alreadyInThisOrder = _units.any(
                (u) =>
                    u.kepalaSticker?.toUpperCase() == normalizedCode ||
                    u.batangSticker?.toUpperCase() == normalizedCode ||
                    u.tabungSticker?.toUpperCase() == normalizedCode,
              );
              if (alreadyInThisOrder) {
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Komponen $normalizedCode sudah dipakai pada order ini.';
                });
                return;
              }

              final history =
                  await widget.gateway.fetchComponentOrderUsageHistory(
                normalizedCode,
                forceRefresh: true,
              );
              final currentOrderId = widget.order.id;
              final currentOrderanId = widget.order.orderanId;

              final activeHistory =
                  history.cast<Map<String, Object?>?>().firstWhere(
                (h) {
                  if (h == null) return false;
                  final hOrderId = h['orderan_id']?.toString().trim();
                  final status =
                      h['status_orderan']?.toString().trim().toLowerCase();
                  final isCurrent = hOrderId == currentOrderId ||
                      hOrderId == currentOrderanId;
                  final isInactive = status == 'selesai' ||
                      status == 'dibatalkan' ||
                      status == 'batal';
                  return !isCurrent && !isInactive;
                },
                orElse: () => null,
              );

              if (activeHistory != null) {
                final otherOrder =
                    activeHistory['orderan_id']?.toString() ?? 'lain';
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Komponen $normalizedCode masih dialokasikan pada order $otherOrder.';
                });
                return;
              }

              int targetIndex = -1;
              for (var i = 0; i < _units.length; i++) {
                final currentVal = switch (expectedKind) {
                  'Kepala' => _units[i].kepalaSticker,
                  'Batang' => _units[i].batangSticker,
                  'Tabung' => _units[i].tabungSticker,
                  _ => null,
                };
                if (currentVal == null || currentVal.isEmpty) {
                  targetIndex = i;
                  break;
                }
              }

              if (targetIndex == -1) {
                setDialogState(() {
                  isProcessing = false;
                  dialogError =
                      'Semua unit sudah memiliki komponen $expectedKind.';
                });
                return;
              }

              final updatedUnits = List<AllocatedUnit>.from(_units);
              final oldUnit = updatedUnits[targetIndex];
              updatedUnits[targetIndex] = switch (expectedKind) {
                'Kepala' => oldUnit.copyWith(kepalaSticker: normalizedCode),
                'Batang' => oldUnit.copyWith(batangSticker: normalizedCode),
                'Tabung' => oldUnit.copyWith(tabungSticker: normalizedCode),
                _ => oldUnit,
              };

              final orderanId = widget.order.orderanId ?? widget.order.id;
              await widget.gateway.saveOrderUnitAllocation(
                orderanId,
                updatedUnits,
              );

              setState(() {
                _units = updatedUnits;
              });
              widget.onAllocationChanged?.call(updatedUnits);

              if (ctx.mounted) {
                Navigator.of(ctx).pop(true);
              }
            } catch (e) {
              setDialogState(() {
                isProcessing = false;
                dialogError =
                    'Terjadi kendala saat memeriksa komponen. Coba lagi.';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.card),
            ),
            title: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: MgrsColors.action),
                SizedBox(width: MgrsSpacing.xs),
                Expanded(
                  child: Text(
                    'Scan barcode komponen',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MgrsColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(MgrsRadii.control),
                      child: SizedBox(
                        height: 180,
                        child: MobileScanner(
                          onDetect: (capture) {
                            if (isProcessing) return;
                            final barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final val =
                                  barcode.rawValue?.trim().toUpperCase();
                              if (val != null && val.isNotEmpty) {
                                processCode(val);
                                return;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: MgrsSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(MgrsSpacing.sm),
                        decoration: BoxDecoration(
                          color: MgrsColors.dangerSoft,
                          borderRadius:
                              BorderRadius.circular(MgrsRadii.control),
                          border: Border.all(color: MgrsColors.danger),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MgrsColors.danger,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: MgrsSpacing.md),
                    const Text(
                      'Kode stiker:',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MgrsColors.muted,
                      ),
                    ),
                    const SizedBox(height: MgrsSpacing.xs),
                    TextField(
                      controller: textCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: K-01',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: MgrsSpacing.md,
                          vertical: MgrsSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(MgrsRadii.control),
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty && !isProcessing) {
                          processCode(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isProcessing
                    ? null
                    : () {
                        if (textCtrl.text.trim().isNotEmpty) {
                          processCode(textCtrl.text);
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Gunakan kode'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _units.where((u) => u.isComplete).length;
    final totalCount = _units.length;

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MgrsSpacing.xs,
            runSpacing: 4,
            children: [
              const Text(
                'Alokasi Unit Blower',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.ink,
                ),
              ),
              const MgrsStatusBadge('Opsional', tone: MgrsStatusTone.warning),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$completedCount dari $totalCount unit lengkap',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MgrsColors.muted,
            ),
          ),
          if (widget.isEditable) ...[
            const SizedBox(height: MgrsSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                final recBtn = OutlinedButton.icon(
                  onPressed: _isRecommending ? null : _applyRecommendation,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: _isRecommending
                      ? const Text('Mencari...')
                      : const Text('Rekomendasi Tersegar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MgrsSpacing.sm,
                      vertical: MgrsSpacing.xs,
                    ),
                    minimumSize: const Size(0, MgrsSizes.minTouch),
                  ),
                );

                final scanBtn = FilledButton.icon(
                  onPressed: _showScanDialog,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Scan Barcode'),
                  style: FilledButton.styleFrom(
                    backgroundColor: MgrsColors.action,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MgrsSpacing.sm,
                      vertical: MgrsSpacing.xs,
                    ),
                    minimumSize: const Size(0, MgrsSizes.minTouch),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      recBtn,
                      const SizedBox(height: MgrsSpacing.xs),
                      scanBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: recBtn),
                    const SizedBox(width: MgrsSpacing.sm),
                    Expanded(child: scanBtn),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: MgrsSpacing.sm),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _units.length,
            separatorBuilder: (_, index) => const SizedBox(height: MgrsSpacing.sm),
            itemBuilder: (context, index) {
              return _buildUnitAllocationRow(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitAllocationRow(int unitIndex) {
    final unit = _units[unitIndex];
    final isComplete = unit.isComplete;

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.sm),
      decoration: BoxDecoration(
        color: MgrsColors.canvas,
        borderRadius: BorderRadius.circular(MgrsRadii.control),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MgrsSpacing.xs,
            runSpacing: 4,
            children: [
              Text(
                'Unit ${unitIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MgrsColors.ink,
                ),
              ),
              MgrsStatusBadge(
                isComplete ? 'Lengkap' : 'Belum Lengkap',
                tone: isComplete
                    ? MgrsStatusTone.success
                    : MgrsStatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 300;
              final slotKepala = _buildSlotWidget(
                unitIndex: unitIndex,
                kind: 'Kepala',
                sticker: unit.kepalaSticker,
              );
              final slotBatang = _buildSlotWidget(
                unitIndex: unitIndex,
                kind: 'Batang',
                sticker: unit.batangSticker,
              );
              final slotTabung = _buildSlotWidget(
                unitIndex: unitIndex,
                kind: 'Tabung',
                sticker: unit.tabungSticker,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    slotKepala,
                    const SizedBox(height: MgrsSpacing.xs),
                    slotBatang,
                    const SizedBox(height: MgrsSpacing.xs),
                    slotTabung,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: slotKepala),
                  const SizedBox(width: MgrsSpacing.xs),
                  Expanded(child: slotBatang),
                  const SizedBox(width: MgrsSpacing.xs),
                  Expanded(child: slotTabung),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotWidget({
    required int unitIndex,
    required String kind,
    required String? sticker,
  }) {
    final isOccupied = sticker != null && sticker.isNotEmpty;
    final wearCount = isOccupied ? (_usageCounts[sticker] ?? 0) : null;

    return InkWell(
      onTap: widget.isEditable ? () => _pickComponent(unitIndex, kind) : null,
      borderRadius: BorderRadius.circular(MgrsRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MgrsSpacing.xs,
          vertical: MgrsSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: MgrsColors.surface,
          borderRadius: BorderRadius.circular(MgrsRadii.control),
          border: Border.all(
            color: isOccupied ? MgrsColors.action : MgrsColors.line,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              kind,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: MgrsColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            if (isOccupied) ...[
              Text(
                sticker,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.action,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${wearCount ?? 0}x pakai',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MgrsColors.muted,
                ),
              ),
              if (widget.isEditable) ...[
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _clearComponent(unitIndex, kind),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: MgrsColors.danger,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 16,
                color: MgrsColors.muted,
              ),
              const SizedBox(height: 2),
              const Text(
                'Pilih',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MgrsColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
