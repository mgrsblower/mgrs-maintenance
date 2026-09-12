import 'package:flutter/foundation.dart';

@immutable
class AllocatedUnit {
  const AllocatedUnit({
    required this.unitIndex,
    this.kepalaSticker,
    this.batangSticker,
    this.tabungSticker,
  });

  final int unitIndex;
  final String? kepalaSticker;
  final String? batangSticker;
  final String? tabungSticker;

  bool get isEmpty =>
      (kepalaSticker == null || kepalaSticker!.trim().isEmpty) &&
      (batangSticker == null || batangSticker!.trim().isEmpty) &&
      (tabungSticker == null || tabungSticker!.trim().isEmpty);

  bool get isComplete =>
      kepalaSticker != null &&
      kepalaSticker!.trim().isNotEmpty &&
      batangSticker != null &&
      batangSticker!.trim().isNotEmpty &&
      tabungSticker != null &&
      tabungSticker!.trim().isNotEmpty;

  AllocatedUnit copyWith({
    int? unitIndex,
    String? kepalaSticker,
    String? batangSticker,
    String? tabungSticker,
    bool clearKepala = false,
    bool clearBatang = false,
    bool clearTabung = false,
  }) {
    return AllocatedUnit(
      unitIndex: unitIndex ?? this.unitIndex,
      kepalaSticker: clearKepala ? null : (kepalaSticker ?? this.kepalaSticker),
      batangSticker: clearBatang ? null : (batangSticker ?? this.batangSticker),
      tabungSticker: clearTabung ? null : (tabungSticker ?? this.tabungSticker),
    );
  }
}

abstract final class UnitAllocationParser {
  static final RegExp allocationPattern =
      RegExp(r'\[UNIT_ALOKASI:\s*([^\]]+)\]', caseSensitive: false);

  static List<AllocatedUnit> parse(String? rawNote, {int? totalUnits}) {
    final note = rawNote ?? '';
    final match = allocationPattern.firstMatch(note);

    final parsedMap = <int, AllocatedUnit>{};

    if (match != null) {
      final rawUnits = match.group(1)?.split('|') ?? [];
      for (var i = 0; i < rawUnits.length; i++) {
        final unitStr = rawUnits[i].trim();
        if (unitStr.isEmpty) continue;
        final parts = unitStr.split('+');
        final k = parts.isNotEmpty && parts[0].trim() != '-' ? parts[0].trim() : null;
        final b = parts.length > 1 && parts[1].trim() != '-' ? parts[1].trim() : null;
        final t = parts.length > 2 && parts[2].trim() != '-' ? parts[2].trim() : null;
        parsedMap[i + 1] = AllocatedUnit(
          unitIndex: i + 1,
          kepalaSticker: k,
          batangSticker: b,
          tabungSticker: t,
        );
      }
    }

    final maxParsed = parsedMap.keys.isEmpty
        ? 0
        : parsedMap.keys.reduce((a, b) => a > b ? a : b);
    final count = totalUnits != null && totalUnits > 0
        ? (totalUnits > maxParsed ? totalUnits : maxParsed)
        : (maxParsed > 0 ? maxParsed : 1);

    final result = <AllocatedUnit>[];
    for (var i = 1; i <= count; i++) {
      result.add(parsedMap[i] ?? AllocatedUnit(unitIndex: i));
    }
    return result;
  }

  static String serialize(List<AllocatedUnit> units) {
    final nonEmpty = units.where((u) => !u.isEmpty).toList();
    if (nonEmpty.isEmpty) return '';

    final parts = units.map((u) {
      final k = u.kepalaSticker?.trim().isNotEmpty == true ? u.kepalaSticker!.trim() : '-';
      final b = u.batangSticker?.trim().isNotEmpty == true ? u.batangSticker!.trim() : '-';
      final t = u.tabungSticker?.trim().isNotEmpty == true ? u.tabungSticker!.trim() : '-';
      return '$k+$b+$t';
    }).join(' | ');

    return '[UNIT_ALOKASI: $parts]';
  }

  static String updateNoteWithAllocation(String? existingNote, List<AllocatedUnit> units) {
    final note = (existingNote ?? '').replaceAll(allocationPattern, '').trim();
    final tag = serialize(units);
    if (tag.isEmpty) return note;
    return note.isNotEmpty ? '$note\n$tag' : tag;
  }
}
