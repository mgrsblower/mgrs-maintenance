import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

class MockGatewayWithAllocation extends MaintenanceGateway {
  final List<OrderanSewa> orders;
  MockGatewayWithAllocation(this.orders);

  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('u-1', 'Tim Pemasangan');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async => orders;

  @override
  Future<Map<String, int>> fetchComponentUsageCounts({
    bool forceRefresh = false,
  }) async {
    final counts = <String, int>{};
    for (final o in orders) {
      for (final u in o.allocatedUnits) {
        if (u.kepalaSticker != null) {
          counts[u.kepalaSticker!] = (counts[u.kepalaSticker!] ?? 0) + 1;
        }
        if (u.batangSticker != null) {
          counts[u.batangSticker!] = (counts[u.batangSticker!] ?? 0) + 1;
        }
        if (u.tabungSticker != null) {
          counts[u.tabungSticker!] = (counts[u.tabungSticker!] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  @override
  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {
    final idx = orders.indexWhere(
      (o) => o.orderanId == orderanId || o.id == orderanId,
    );
    if (idx != -1) {
      final updatedNote = UnitAllocationParser.updateNoteWithAllocation(
        orders[idx].catatanOrderan,
        units,
      );
      orders[idx] = orders[idx].copyWith(catatanOrderan: updatedNote);
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentOrderUsageHistory(
    String sticker, {
    bool forceRefresh = false,
  }) async {
    final history = <Map<String, Object?>>[];
    for (final o in orders) {
      for (final u in o.allocatedUnits) {
        String? matchedKind;
        if (u.kepalaSticker == sticker) matchedKind = 'Kepala';
        if (u.batangSticker == sticker) matchedKind = 'Batang';
        if (u.tabungSticker == sticker) matchedKind = 'Tabung';
        if (matchedKind != null) {
          history.add({
            'orderan_id': o.orderanId ?? o.id,
            'nama_event': o.namaEvent,
            'nama_client': o.namaClient ?? '-',
            'unit_index': u.unitIndex,
            'role_slot': matchedKind,
          });
        }
      }
    }
    return history;
  }
}

void main() {
  group('Gateway Unit Allocation & Usage Counts Tests', () {
    test('Usage counts aggregation across past orders', () async {
      final orders = [
        OrderanSewa(
          id: '1',
          orderanId: 'ORD-001',
          namaEvent: 'Event A',
          jumlahUnit: 2,
          catatanOrderan: '[UNIT_ALOKASI: K-01+B-01+T-01 | K-02+B-02+T-02]',
        ),
        OrderanSewa(
          id: '2',
          orderanId: 'ORD-002',
          namaEvent: 'Event B',
          jumlahUnit: 1,
          catatanOrderan: '[UNIT_ALOKASI: K-01+B-05+T-01]',
        ),
      ];

      final gateway = MockGatewayWithAllocation(orders);
      final counts = await gateway.fetchComponentUsageCounts();

      expect(counts['K-01'], equals(2));
      expect(counts['K-02'], equals(1));
      expect(counts['B-01'], equals(1));
      expect(counts['B-05'], equals(1));
      expect(counts['T-01'], equals(2));
      expect(counts['T-02'], equals(1));
      expect(counts['K-99'], isNull);
    });

    test(
      'Component order usage history retrieves all orders where component was used',
      () async {
        final orders = [
          OrderanSewa(
            id: '1',
            orderanId: 'ORD-001',
            namaEvent: 'Event A',
            namaClient: 'Budi',
            jumlahUnit: 2,
            catatanOrderan: '[UNIT_ALOKASI: K-01+B-01+T-01 | K-02+B-02+T-02]',
          ),
          OrderanSewa(
            id: '2',
            orderanId: 'ORD-002',
            namaEvent: 'Event B',
            namaClient: 'Siti',
            jumlahUnit: 1,
            catatanOrderan: '[UNIT_ALOKASI: K-01+B-05+T-01]',
          ),
        ];

        final gateway = MockGatewayWithAllocation(orders);
        final historyK01 = await gateway.fetchComponentOrderUsageHistory(
          'K-01',
        );
        expect(historyK01.length, equals(2));
        expect(historyK01[0]['orderan_id'], equals('ORD-001'));
        expect(historyK01[1]['orderan_id'], equals('ORD-002'));

        final historyK02 = await gateway.fetchComponentOrderUsageHistory(
          'K-02',
        );
        expect(historyK02.length, equals(1));
        expect(historyK02[0]['unit_index'], equals(2));
      },
    );

    test(
      'Saving order unit allocation updates catatanOrderan correctly',
      () async {
        final orders = [
          OrderanSewa(
            id: '1',
            orderanId: 'ORD-001',
            namaEvent: 'Event A',
            jumlahUnit: 1,
            catatanOrderan: '[SEWA_HARI:3] Catatan awal',
          ),
        ];

        final gateway = MockGatewayWithAllocation(orders);
        const units = [
          AllocatedUnit(
            unitIndex: 1,
            kepalaSticker: 'K-05',
            batangSticker: 'B-10',
            tabungSticker: 'T-15',
          ),
        ];

        await gateway.saveOrderUnitAllocation('ORD-001', units);

        final updated = gateway.orders.first;
        expect(updated.allocatedUnits.first.kepalaSticker, equals('K-05'));
        expect(updated.allocatedUnits.first.batangSticker, equals('B-10'));
        expect(updated.allocatedUnits.first.tabungSticker, equals('T-15'));
        expect(updated.cleanNote, equals('Catatan awal'));
      },
    );
  });
}
