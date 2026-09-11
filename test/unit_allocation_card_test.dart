import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_card.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

class MockCardGateway extends MaintenanceGateway {
  final Map<String, String> savedNotes = {};

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
  Future<Map<String, int>> fetchComponentUsageCounts({bool forceRefresh = false}) async {
    return {
      'K-01': 2,
      'K-02': 10,
      'B-01': 1,
      'B-02': 8,
      'T-01': 0,
      'T-02': 5,
    };
  }

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
    } else if (kind == 'Batang') {
      return [
        {'nomor_stiker': 'B-01', 'jenis_komponen': 'Batang', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
        {'nomor_stiker': 'B-02', 'jenis_komponen': 'Batang', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      ];
    } else if (kind == 'Tabung') {
      return [
        {'nomor_stiker': 'T-01', 'jenis_komponen': 'Tabung', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
        {'nomor_stiker': 'T-02', 'jenis_komponen': 'Tabung', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      ];
    }
    return [];
  }

  @override
  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {
    savedNotes[orderanId] = UnitAllocationParser.updateNoteWithAllocation(
      savedNotes[orderanId],
      units,
    );
  }
}

void main() {
  testWidgets('UnitAllocationCard renders allocated units and shows wear counts', (tester) async {
    final gateway = MockCardGateway();
    final order = OrderanSewa(
      id: 'ord-100',
      namaEvent: 'Pak Budi Wedding',
      nomorWhatsapp: '0812345',
      alamat: 'Gedung A',
      jumlahUnit: 1,
      catatanOrderan: 'Acara indoor [UNIT_ALOKASI: K-01+B-01+T-01]',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UnitAllocationCard(
              gateway: gateway,
              order: order,
              isEditable: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Badges
    expect(find.text('Alokasi Unit Blower'), findsOneWidget);
    expect(find.text('Opsional'), findsOneWidget);

    // Verify Stalker stickers rendered
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);

    // Verify usage counts rendered
    expect(find.text('2x pakai'), findsOneWidget);
    expect(find.text('1x pakai'), findsOneWidget);
    expect(find.text('0x pakai'), findsOneWidget);
  });

  testWidgets('UnitAllocationCard Rekomendasi Tersegar auto-fills least used units', (tester) async {
    final gateway = MockCardGateway();
    final order = OrderanSewa(
      id: 'ord-200',
      namaEvent: 'Bu Siti Party',
      nomorWhatsapp: '0812345',
      alamat: 'Gedung B',
      jumlahUnit: 1,
      catatanOrderan: 'Kosong belum ada unit',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UnitAllocationCard(
              gateway: gateway,
              order: order,
              isEditable: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Rekomendasi Tersegar
    final recButton = find.text('Rekomendasi Tersegar');
    expect(recButton, findsOneWidget);
    await tester.tap(recButton);
    await tester.pumpAndSettle();

    // K-01 (2x) is least used compared to K-02 (10x)
    // B-01 (1x) is least used compared to B-02 (8x)
    // T-01 (0x) is least used compared to T-02 (5x)
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);

    // Verify saved to gateway
    expect(gateway.savedNotes['ord-200'], contains('[UNIT_ALOKASI: K-01+B-01+T-01]'));
  });

  testWidgets('UnitAllocationCard read-only mode hides modification buttons', (tester) async {
    final gateway = MockCardGateway();
    final order = OrderanSewa(
      id: 'ord-300',
      namaEvent: 'Bu Siti Exhibition',
      nomorWhatsapp: '0812345',
      alamat: 'Gedung C',
      jumlahUnit: 1,
      catatanOrderan: '[UNIT_ALOKASI: K-02+B-02+T-02]',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UnitAllocationCard(
              gateway: gateway,
              order: order,
              isEditable: false, // PIC or Completed
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Recommendation and Scan buttons should not be shown
    expect(find.text('Rekomendasi Tersegar'), findsNothing);
    expect(find.text('Scan Barcode'), findsNothing);

    // Sticking should still be displayed
    expect(find.text('K-02'), findsOneWidget);
  });
}
