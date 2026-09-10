import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

class MockAdminGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('admin-1', 'Admin', fullName: 'Super Administrator');

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
      {'kode_aset': 'BLW-01', 'nama_komponen': 'Blower Fan Unit 01', 'kondisi': 'OK'},
      {'kode_aset': 'PMP-02', 'nama_komponen': 'Water Pump 02', 'kondisi': 'Service'},
    ];
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    return [
      OrderanSewa(
        id: 'ord-1',
        namaEvent: 'Konser Musik Solo',
        namaClient: 'Bpk Joko',
        alamat: 'Stadion Manahan',
        tanggalPemasangan: DateTime.now(),
        statusOrderan: 'Terjadwal',
      ),
    ];
  }

  @override
  Future<List<InvoiceRecord>> fetchInvoices({
    String? orderanId,
    InvoicePaymentStatus? status,
    String? source,
    bool forceRefresh = false,
  }) async {
    return [];
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String? periodId,
    bool forceRefresh = false,
  }) async => {'total': 2, 'completed': 1};

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async => [];
}

void main() {
  testWidgets('Admin user can switch between Mode PIC and Mode Servis safely via profile sheet',
      (WidgetTester tester) async {
    final gateway = MockAdminGateway();
    const adminUser = UserProfile(
      'admin-1',
      'Admin',
      fullName: 'Super Administrator',
      username: 'admin',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MaintenanceHome(
          gateway: gateway,
          user: adminUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial default state for Admin is Mode Servis (Maintenance Technician flow)
    expect(find.text('Aset'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);

    // 2. Tap profile avatar in header to open profile sheet
    final avatarFinder = find.text('SA'); // Initials of Super Administrator
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();

    // 3. Verify Mode Tampilan (Khusus Admin) section is present in sheet
    expect(find.text('Mode Tampilan (Khusus Admin)'), findsOneWidget);
    expect(find.text('Mode PIC'), findsOneWidget);
    expect(find.text('Mode Servis'), findsOneWidget);

    // 4. Tap "Mode PIC" to switch to PIC order & invoice flow
    await tester.tap(find.text('Mode PIC'));
    await tester.pumpAndSettle();

    // 5. Verify now switched to PIC Mode
    expect(find.text('Orderan'), findsWidgets);
    expect(find.text('Invoice'), findsWidgets);
    expect(find.text('Total Orderan\nBulan Ini'), findsOneWidget);

    // 6. Tap avatar in PIC header to switch back to Servis
    await tester.tap(find.text('SA'));
    await tester.pumpAndSettle();

    expect(find.text('Mode Tampilan (Khusus Admin)'), findsOneWidget);
    await tester.tap(find.text('Mode Servis'));
    await tester.pumpAndSettle();

    // 7. Verify back to Mode Servis
    expect(find.text('Aset'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
  });
}
