# Optional Unit Selection and Wear-and-Tear Balancing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide Tim Pemasangan and Admin with an optional feature to allocate 3-component blower units (Kepala, Batang, Tabung) per order with usage-count rotation recommendations and quick barcode scanning.

**Architecture:** 
- Each unit consists of 3 distinct component slots: Kepala (`K-xx`), Batang (`B-xx`), Tabung (`T-xx`).
- Unit allocation is saved as non-invasive metadata in `catatan_orderan` (`[UNIT_ALOKASI: K-01+B-01+T-01 | K-02+B-02+T-02]`), keeping Supabase database schemas safe.
- Gateway dynamically aggregates component usage counts across order history, prioritizing least-used components at the top of picker lists and in 1-tap "Rekomendasi Tersegar".
- Integration with camera barcode scanning automatically routes scanned stickers to matching component slots.

**Tech Stack:** Flutter / Dart, Supabase Flutter client, plus_jakarta_sans styling.

## Global Constraints
- **100% Optional:** Orders must never be blocked if no units are allocated. No mandatory post-event reports.
- **Component Kinds:** Exactly 3 components per unit: `Kepala`, `Batang`, `Tabung`.
- **Database Safety:** Do not modify table schema or triggers; use structured metadata tag in `orderan_sewa.catatan_orderan`.
- **Target Audience:** Tim Pemasangan and Admin have write/edit access; PIC has monitoring/read-only access.

---

### Task 1: Unit Allocation Models & Metadata Serialization

**Files:**
- Create: `lib/features/schedule/unit_allocation_model.dart`
- Modify: `lib/features/schedule/order_model.dart`
- Test: `test/unit_allocation_model_test.dart`

**Interfaces:**
- Consumes: `OrderanSewa` from `lib/features/schedule/order_model.dart`
- Produces: `AllocatedUnit`, `UnitAllocationParser`

- [ ] **Step 1: Write the failing unit tests for model and parser**

Create `test/unit_allocation_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

void main() {
  group('AllocatedUnit & UnitAllocationParser Tests', () {
    test('AllocatedUnit properties and copyWith', () {
      const unit = AllocatedUnit(
        unitIndex: 1,
        kepalaSticker: 'K-01',
        batangSticker: 'B-02',
        tabungSticker: 'T-03',
      );

      expect(unit.unitIndex, equals(1));
      expect(unit.isComplete, isTrue);
      expect(unit.isEmpty, isFalse);

      final cleared = unit.copyWith(clearKepala: true);
      expect(cleared.kepalaSticker, isNull);
      expect(cleared.batangSticker, equals('B-02'));
      expect(cleared.isComplete, isFalse);
    });

    test('UnitAllocationParser parses tag correctly', () {
      const rawTag = '[UNIT_ALOKASI: K-01+B-02+T-03 | K-05+B-08+T-10]';
      final units = UnitAllocationParser.parse(rawTag, totalUnits: 3);

      expect(units.length, equals(3));
      expect(units[0].kepalaSticker, equals('K-01'));
      expect(units[0].batangSticker, equals('B-02'));
      expect(units[0].tabungSticker, equals('T-03'));
      expect(units[1].kepalaSticker, equals('K-05'));
      expect(units[2].isEmpty, isTrue);
    });

    test('UnitAllocationParser serializes units into tag string', () {
      const units = [
        AllocatedUnit(unitIndex: 1, kepalaSticker: 'K-01', batangSticker: 'B-02', tabungSticker: 'T-03'),
        AllocatedUnit(unitIndex: 2, kepalaSticker: 'K-05', batangSticker: null, tabungSticker: 'T-10'),
      ];

      final serialized = UnitAllocationParser.serialize(units);
      expect(serialized, equals('[UNIT_ALOKASI: K-01+B-02+T-03 | K-05+-+T-10]'));
    });

    test('OrderanSewa allocatedUnits getter and cleanNote ignores allocation tag', () {
      final order = OrderanSewa(
        id: 'ord-1',
        namaEvent: 'Konser',
        jumlahUnit: 2,
        catatanOrderan: '[SEWA_HARI:2] [UNIT_ALOKASI: K-01+B-01+T-01] Catatan teknis lapangan',
      );

      expect(order.allocatedUnits.length, equals(2));
      expect(order.allocatedUnits[0].kepalaSticker, equals('K-01'));
      expect(order.allocatedUnits[1].isEmpty, isTrue);
      expect(order.cleanNote, equals('Catatan teknis lapangan'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit_allocation_model_test.dart`
Expected: FAIL (file or classes not defined).

- [ ] **Step 3: Implement AllocatedUnit and UnitAllocationParser**

Create `lib/features/schedule/unit_allocation_model.dart`:
```dart
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

  static List<AllocatedUnit> parse(String? rawNote, {int totalUnits = 1}) {
    final note = rawNote ?? '';
    final match = allocationPattern.firstMatch(note);
    final count = totalUnits > 0 ? totalUnits : 1;

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
```

- [ ] **Step 4: Update OrderanSewa in `lib/features/schedule/order_model.dart`**

Add import of `unit_allocation_model.dart`, define `_unitAllocationPattern = RegExp(r'\[UNIT_ALOKASI:\s*[^\]]+\]', caseSensitive: false);`, add `allocatedUnits` getter, and update `cleanNote` to remove `_unitAllocationPattern`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/unit_allocation_model_test.dart`
Expected: PASS (All tests passed).

- [ ] **Step 6: Commit**

```bash
git add lib/features/schedule/unit_allocation_model.dart lib/features/schedule/order_model.dart test/unit_allocation_model_test.dart
git commit -m "feat: add AllocatedUnit model and metadata parser"
```

---

### Task 2: Component Usage Balancing Logic & Gateway Integration

**Files:**
- Modify: `lib/app/gateway.dart`
- Test: `test/unit_allocation_gateway_test.dart`

**Interfaces:**
- Consumes: `AllocatedUnit`, `UnitAllocationParser`
- Produces: `MaintenanceGateway.fetchComponentUsageCounts()`, `MaintenanceGateway.saveOrderUnitAllocation()`

- [ ] **Step 1: Write test for gateway usage counts and allocation persistence**

Create `test/unit_allocation_gateway_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

void main() {
  test('Usage counts aggregation across orders', () {
    final orders = [
      OrderanSewa(
        id: '1',
        namaEvent: 'Event A',
        catatanOrderan: '[UNIT_ALOKASI: K-01+B-01+T-01 | K-02+B-02+T-02]',
      ),
      OrderanSewa(
        id: '2',
        namaEvent: 'Event B',
        catatanOrderan: '[UNIT_ALOKASI: K-01+B-05+T-01]',
      ),
    ];

    final counts = <String, int>{};
    for (final o in orders) {
      for (final u in o.allocatedUnits) {
        if (u.kepalaSticker != null) counts[u.kepalaSticker!] = (counts[u.kepalaSticker!] ?? 0) + 1;
        if (u.batangSticker != null) counts[u.batangSticker!] = (counts[u.batangSticker!] ?? 0) + 1;
        if (u.tabungSticker != null) counts[u.tabungSticker!] = (counts[u.tabungSticker!] ?? 0) + 1;
      }
    }

    expect(counts['K-01'], equals(2));
    expect(counts['K-02'], equals(1));
    expect(counts['B-01'], equals(1));
    expect(counts['B-05'], equals(1));
    expect(counts['T-01'], equals(2));
  });
}
```

- [ ] **Step 2: Add methods to `MaintenanceGateway` in `lib/app/gateway.dart`**

```dart
  Future<Map<String, int>> fetchComponentUsageCounts({bool forceRefresh = false}) async => {};

  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {}
```

- [ ] **Step 3: Implement in `SupabaseGateway` in `lib/app/gateway.dart`**

Implement `fetchComponentUsageCounts` by scanning past orders' `catatan_orderan` and parsing `UnitAllocationParser.allocationPattern`.
Implement `saveOrderUnitAllocation` by updating `catatan_orderan` on `orderan_sewa` using `UnitAllocationParser.updateNoteWithAllocation`.
Invalidate caches `'upcoming_orders'` and `'order_detail:$orderanId'`.

- [ ] **Step 4: Run tests and verify analyze passes**

Run: `flutter test test/unit_allocation_gateway_test.dart` and `flutter analyze`.
Expected: PASS with 0 issues.

- [ ] **Step 5: Commit**

```bash
git add lib/app/gateway.dart test/unit_allocation_gateway_test.dart
git commit -m "feat: add component usage counts and allocation saving to gateway"
```

---

### Task 3: Component Picker Bottom Sheet with Wear-and-Tear Sort

**Files:**
- Create: `lib/features/schedule/component_picker_sheet.dart`
- Test: `test/component_picker_sheet_test.dart`

**Interfaces:**
- Consumes: `MaintenanceGateway`, `kind` ('Kepala' | 'Batang' | 'Tabung'), `currentSticker`, `usageCounts`
- Produces: `showComponentPickerSheet(...)` returning `String? selectedSticker`

- [ ] **Step 1: Write widget test for ComponentPickerSheet**

Create `test/component_picker_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/component_picker_sheet.dart';

class MockPickerGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('u-1', 'Tim Pemasangan');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async {
    return [
      {'nomor_stiker': 'K-01', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      {'nomor_stiker': 'K-02', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      {'nomor_stiker': 'K-03', 'jenis_komponen': 'Kepala', 'kondisi': 'Service', 'boleh_dipakai': 'Tidak'},
    ];
  }
}

void main() {
  testWidgets('ComponentPickerSheet sorts by least used and allows selection', (tester) async {
    final gateway = MockPickerGateway();
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await showComponentPickerSheet(
                  context,
                  gateway: gateway,
                  kind: 'Kepala',
                  usageCounts: {'K-01': 10, 'K-02': 2},
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.textContaining('Pilih Kepala Blower'), findsOneWidget);

    // K-02 (2x pakai) should appear before K-01 (10x pakai)
    expect(find.text('K-02'), findsOneWidget);
    expect(find.text('2x pakai'), findsOneWidget);
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('10x pakai'), findsOneWidget);

    // Tap K-02
    await tester.tap(find.text('K-02'));
    await tester.pumpAndSettle();

    expect(selected, equals('K-02'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/component_picker_sheet_test.dart`
Expected: FAIL (showComponentPickerSheet not found).

- [ ] **Step 3: Implement `ComponentPickerSheet`**

Create `lib/features/schedule/component_picker_sheet.dart`:
- Modern modal bottom sheet with search input.
- Queries components matching `kind` using `gateway.fetchComponents(kind: kind)`.
- Filters to `boleh_dipakai == 'Ya'` and `kondisi != 'Rusak Berat'`.
- Sorts ascending by `usageCounts[sticker] ?? 0`.
- Renders badges:
  - `count <= 5`: Green badge `⚡ Xx pakai`
  - `count <= 15`: Amber badge `⚡ Xx pakai`
  - `count > 15`: Slate badge `⚡ Xx pakai`
- Tapping item pops with `nomor_stiker`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/component_picker_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/schedule/component_picker_sheet.dart test/component_picker_sheet_test.dart
git commit -m "feat: add ComponentPickerSheet with wear-and-tear usage sort"
```

---

### Task 4: Unit Allocation Card & OrderDetailScreen Integration

**Files:**
- Create: `lib/features/schedule/unit_allocation_card.dart`
- Modify: `lib/features/schedule/order_detail_screen.dart`
- Test: `test/unit_allocation_card_test.dart`

**Interfaces:**
- Consumes: `AllocatedUnit`, `ComponentPickerSheet`, `MaintenanceGateway`, `UserProfile`
- Produces: `UnitAllocationCard` widget integrated into `OrderDetailScreen`

- [ ] **Step 1: Write widget test for UnitAllocationCard**

Create `test/unit_allocation_card_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_card.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

class MockAllocGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('u-1', 'Tim Pemasangan');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async {
    if (kind == 'Kepala') {
      return [
        {'nomor_stiker': 'K-01', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
        {'nomor_stiker': 'K-02', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      ];
    }
    if (kind == 'Batang') {
      return [
        {'nomor_stiker': 'B-01', 'jenis_komponen': 'Batang', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      ];
    }
    if (kind == 'Tabung') {
      return [
        {'nomor_stiker': 'T-01', 'jenis_komponen': 'Tabung', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      ];
    }
    return [];
  }
}

void main() {
  testWidgets('UnitAllocationCard renders units and triggers recommendation', (tester) async {
    final gateway = MockAllocGateway();
    var units = [
      const AllocatedUnit(unitIndex: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UnitAllocationCard(
              orderanId: 'ORD-1',
              totalUnits: 1,
              initialUnits: units,
              gateway: gateway,
              isEditable: true,
              usageCounts: const {'K-01': 1, 'B-01': 1, 'T-01': 1},
              onUnitsChanged: (updated) {
                units = updated;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Alokasi Unit Blower (1 Unit)'), findsOneWidget);
    expect(find.text('Unit #1'), findsOneWidget);
    expect(find.text('Kepala'), findsOneWidget);
    expect(find.text('Batang'), findsOneWidget);
    expect(find.text('Tabung'), findsOneWidget);

    // Tap "Rekomendasi Tersegar"
    final recButton = find.text('Rekomendasi Tersegar');
    expect(recButton, findsOneWidget);
    await tester.tap(recButton);
    await tester.pumpAndSettle();

    // Verify slot filled
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit_allocation_card_test.dart`
Expected: FAIL (UnitAllocationCard not found).

- [ ] **Step 3: Implement `UnitAllocationCard`**

Create `lib/features/schedule/unit_allocation_card.dart`:
- Container with border radius 20, white background, matching app design system.
- Header with title `Alokasi Unit Blower ($totalUnits Unit)`, badge `Opsional`.
- Action buttons:
  - `Rekomendasi Tersegar` (icon: `Icons.auto_awesome_rounded`, fills empty slots with lowest-count OK components)
  - `Scan Cepat` (opens scanner, automatically assigns scanned sticker to first matching empty slot by prefix `K-`, `B-`, `T-`)
- For each unit (1..`totalUnits`):
  - Unit header: `Unit #i`
  - 3 rows: Kepala, Batang, Tabung
  - If empty: Outlined button with `+ Pilih [Jenis]`
  - If allocated: Chip with sticker code, usage badge, and clear button `(x)`
- On every change: calls `widget.onUnitsChanged(units)` and saves via `gateway.saveOrderUnitAllocation`.

- [ ] **Step 4: Integrate into `OrderDetailScreen` in `lib/features/schedule/order_detail_screen.dart`**

- Fetch usage counts via `widget.gateway?.fetchComponentUsageCounts()` during `_loadOrderDetail()`.
- Add `UnitAllocationCard` right below `_buildVenueCard` or `_buildOrderHeaderCard`.
- Pass `isEditable = widget.user?.isTechnician == true || widget.user?.isAdmin == true`.
- For `PIC Pemasangan`, render in view mode (read-only) if units are assigned.

- [ ] **Step 5: Run tests and verify analyze passes**

Run: `flutter test test/unit_allocation_card_test.dart` and `flutter analyze`.
Expected: PASS with 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/schedule/unit_allocation_card.dart lib/features/schedule/order_detail_screen.dart test/unit_allocation_card_test.dart
git commit -m "feat: integrate UnitAllocationCard in OrderDetailScreen"
```

---

### Task 5: End-to-End Tests & Final Verification

**Files:**
- Create: `test/unit_allocation_flow_test.dart`

- [ ] **Step 1: Write comprehensive end-to-end integration test**

Create `test/unit_allocation_flow_test.dart`:
- Test Tim Pemasangan viewing order, opening component picker, assigning components.
- Test 1-tap auto-recommendation filling units.
- Test order completion succeeds even if NO units are allocated (proving optionality).
- Test usage counts reflect updated allocation.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: 100% tests pass (all existing + new tests).

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 4: Commit**

```bash
git add test/unit_allocation_flow_test.dart
git commit -m "test: add end-to-end unit allocation and balancing test suite"
```
