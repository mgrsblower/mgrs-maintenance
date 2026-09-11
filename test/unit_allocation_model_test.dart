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
      expect(cleared.tabungSticker, equals('T-03'));
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
      expect(units[1].batangSticker, equals('B-08'));
      expect(units[1].tabungSticker, equals('T-10'));
      expect(units[2].isEmpty, isTrue);
    });

    test('UnitAllocationParser parses all units when totalUnits is omitted', () {
      const rawTag = '[UNIT_ALOKASI: K-19+B-08+T-15 | K-07+B-14+T-05]';
      final units = UnitAllocationParser.parse(rawTag);

      expect(units.length, equals(2));
      expect(units[0].kepalaSticker, equals('K-19'));
      expect(units[0].batangSticker, equals('B-08'));
      expect(units[0].tabungSticker, equals('T-15'));
      expect(units[1].kepalaSticker, equals('K-07'));
      expect(units[1].batangSticker, equals('B-14'));
      expect(units[1].tabungSticker, equals('T-05'));
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
      expect(order.allocatedUnits[0].batangSticker, equals('B-01'));
      expect(order.allocatedUnits[0].tabungSticker, equals('T-01'));
      expect(order.allocatedUnits[1].isEmpty, isTrue);
      expect(order.cleanNote, equals('Catatan teknis lapangan'));
    });
  });
}
