import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';

class FlowMockGateway extends MaintenanceGateway {
  FlowMockGateway({required this.order});

  OrderanSewa order;
  final List<String> statusUpdates = [];

  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('u-tech', 'Tim Pemasangan');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<OrderanSewa?> fetchOrderDetail(String id, {bool forceRefresh = false}) async {
    return order;
  }

  @override
  Future<Map<String, int>> fetchComponentUsageCounts({bool forceRefresh = false}) async {
    return {
      'K-01': 1,
      'K-02': 20,
      'B-01': 3,
      'B-02': 15,
      'T-01': 0,
      'T-02': 12,
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
    final updatedNote = UnitAllocationParser.updateNoteWithAllocation(
      order.catatanOrderan,
      units,
    );
    order = OrderanSewa(
      id: order.id,
      orderanId: order.orderanId,
      namaEvent: order.namaEvent,
      nomorWhatsapp: order.nomorWhatsapp,
      alamat: order.alamat,
      jumlahUnit: order.jumlahUnit,
      statusOrderan: order.statusOrderan,
      catatanOrderan: updatedNote,
    );
  }

  @override
  Future<void> updateOrderStatus(String orderanId, String status) async {
    statusUpdates.add(status);
    order = OrderanSewa(
      id: order.id,
      orderanId: order.orderanId,
      namaEvent: order.namaEvent,
      nomorWhatsapp: order.nomorWhatsapp,
      alamat: order.alamat,
      jumlahUnit: order.jumlahUnit,
      statusOrderan: status,
      catatanOrderan: order.catatanOrderan,
    );
  }
}

void main() {
  testWidgets('End-to-End: Technician allocates units with load-balancing & marks order Selesai', (tester) async {
    final initialOrder = OrderanSewa(
      id: 'ord-flow-1',
      orderanId: 'ord-flow-1',
      namaEvent: 'Konser Musik Gas',
      alamat: 'Lapangan Gasibu',
      jumlahUnit: 2,
      statusOrderan: 'Proses Pemasangan',
      catatanOrderan: 'Order panggung utama',
    );

    final gateway = FlowMockGateway(order: initialOrder);
    const techUser = UserProfile('u-tech', 'Tim Pemasangan');

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailScreen(
          order: initialOrder,
          orderId: initialOrder.id,
          gateway: gateway,
          user: techUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UnitAllocationCard rendered with 2 units
    expect(find.text('Alokasi Unit Blower'), findsOneWidget);
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Unit 2'), findsOneWidget);
    expect(find.text('0 dari 2 unit lengkap'), findsOneWidget);

    // Tap Rekomendasi Tersegar
    await tester.tap(find.text('Rekomendasi Tersegar'));
    await tester.pumpAndSettle();

    // Unit 1 should receive K-01 (1x), B-01 (3x), T-01 (0x)
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);

    // Unit 2 should receive remaining available components: K-02 (20x), B-02 (15x), T-02 (12x)
    expect(find.text('K-02'), findsOneWidget);
    expect(find.text('B-02'), findsOneWidget);
    expect(find.text('T-02'), findsOneWidget);

    // Verify completion status updated
    expect(find.text('2 dari 2 unit lengkap'), findsOneWidget);

    // Verify underlying note has serialized tag
    expect(gateway.order.catatanOrderan, contains('[UNIT_ALOKASI: K-01+B-01+T-01 | K-02+B-02+T-02]'));

    // Clean note hides internal tag
    expect(gateway.order.cleanNote, equals('Order panggung utama'));

  });

  testWidgets('End-to-End: Optionality verified - order can complete with 0 units allocated', (tester) async {
    final unallocatedOrder = OrderanSewa(
      id: 'ord-flow-2',
      orderanId: 'ord-flow-2',
      namaEvent: 'Rapat Dinas',
      alamat: 'Kantor Gubernur',
      jumlahUnit: 1,
      statusOrderan: 'Proses Pemasangan',
      catatanOrderan: 'Unit dibawa terpisah',
    );

    final gateway = FlowMockGateway(order: unallocatedOrder);
    const adminUser = UserProfile('u-admin', 'Admin');

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailScreen(
          order: unallocatedOrder,
          orderId: unallocatedOrder.id,
          gateway: gateway,
          user: adminUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Card shows 0 dari 1 unit lengkap and Opsional badge
    expect(find.text('0 dari 1 unit lengkap'), findsOneWidget);
    expect(find.text('Opsional'), findsOneWidget);

    // Selesai button is still enabled and accessible without error
    final finishButton = find.text('Tandai Selesai');
    expect(finishButton, findsOneWidget);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    final confirmButton = find.text('Ya, Selesaikan');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(gateway.statusUpdates, contains('Selesai'));
  });

  testWidgets('End-to-End: PIC sees allocated units read-only', (tester) async {
    final allocatedOrder = OrderanSewa(
      id: 'ord-flow-3',
      orderanId: 'ord-flow-3',
      namaEvent: 'Seminar Nasional',
      alamat: 'Auditorium UI',
      jumlahUnit: 1,
      statusOrderan: 'Proses Pemasangan',
      catatanOrderan: 'Catatan penting [UNIT_ALOKASI: K-01+B-01+T-01]',
    );

    final gateway = FlowMockGateway(order: allocatedOrder);
    const picUser = UserProfile('u-pic', 'PIC Pemasangan');

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailScreen(
          order: allocatedOrder,
          orderId: allocatedOrder.id,
          gateway: gateway,
          user: picUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify PIC sees the allocated components
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);
    expect(find.text('1 dari 1 unit lengkap'), findsOneWidget);

    // PIC CANNOT see modification buttons
    expect(find.text('Rekomendasi Tersegar'), findsNothing);
    expect(find.text('Scan Barcode'), findsNothing);
  });
}
