import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
import 'package:mgrs_maintenance/features/home/pic_home_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/scan/scan_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';

class MockPicGateway extends MaintenanceGateway {
  final List<OrderanSewa> orders = [
    OrderanSewa(
      id: 'ord-1',
      orderanId: 'ORD-20260910-001',
      namaEvent: 'Pameran Otomotif Akbar',
      namaClient: 'CV Maju Jaya',
      alamat: 'Hall A JICC, Kemayoran',
      jumlahUnit: 4,
      tanggalPemasangan: DateTime.now().subtract(const Duration(days: 1)),
      catatanOrderan: '[SEWA_HARI:3]',
      statusOrderan: 'Terjadwal',
    ),
    OrderanSewa(
      id: 'ord-2',
      orderanId: 'ORD-20260905-002',
      namaEvent: 'Pernikahan Ratna & Dimas',
      namaClient: 'Ibu Ratna Wedding',
      alamat: 'Gedung Arsip Nasional, Jakbar',
      jumlahUnit: 2,
      tanggalPemasangan: DateTime.now().subtract(const Duration(days: 5)),
      catatanOrderan: '[SEWA_HARI:3]',
      statusOrderan: 'Terjadwal', // H+1 has passed, isDatePassed will be true
    ),
  ];

  final List<InvoiceRecord> invoices = [
    const InvoiceRecord(
      id: '1',
      orderanId: 'ORD-20260910-001',
      invoiceReference: 'INV/2026/09/10-001',
      invoiceDate: '2026-09-10',
      dueDate: '2026-09-13',
      productName: 'Sewa Kipas Blower MGRS',
      quantity: 4,
      rentalDays: 3,
      unitPrice: 250000,
      subtotal: 3000000,
      totalAmount: 3000000,
      paidAmount: 0,
      paymentStatus: 'Belum Lunas',
      customerName: 'CV Maju Jaya',
      customerPhone: '081234567890',
    ),
    const InvoiceRecord(
      id: '2',
      orderanId: 'ORD-20260905-002',
      invoiceReference: 'INV/2026/09/05-002',
      invoiceDate: '2026-09-05',
      dueDate: '2026-09-08',
      productName: 'Sewa Kipas Blower MGRS',
      quantity: 2,
      rentalDays: 3,
      unitPrice: 250000,
      subtotal: 1500000,
      totalAmount: 1500000,
      paidAmount: 1500000,
      paymentStatus: 'Lunas',
      customerName: 'Ibu Ratna Wedding',
      customerPhone: '081298765432',
    ),
  ];

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi PIC MGRS');

  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_get_component') {
      return {
        'id': 'c-1',
        'nomor_stiker': 'KPL-001',
        'jenis_komponen': 'Kepala',
        'kondisi': 'OK',
        'boleh_dipakai': 'Ya',
        'fungsi_terganggu': 'Tidak Ada',
        'keterangan': 'Kondisi prima siap event',
      };
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async =>
      [];

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async => [];

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String? periodId,
    bool forceRefresh = false,
  }) async => {'total': 0, 'completed': 0};

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async => orders;

  @override
  Future<List<InvoiceRecord>> fetchInvoices({bool forceRefresh = false}) async =>
      invoices;

  @override
  Future<void> updateOrderStatus(String orderanId, String status) async {
    final idx = orders.indexWhere((o) => o.orderanId == orderanId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(statusOrderan: status);
    }
  }

  @override
  Future<OrderanSewa> createOrderWithInvoice(
    Map<String, Object?> orderData,
  ) async {
    final order = OrderanSewa.fromJson(orderData);
    orders.insert(0, order);
    final inv = InvoiceRecord.fromJson({
      'id': '999',
      'orderan_id': order.orderanId,
      'invoice_reference': 'INV/2026/09/10-999',
      'invoice_date': '2026-09-10',
      'due_date': '2026-09-13',
      'product_name': 'Sewa Kipas Blower MGRS',
      'quantity': order.jumlahUnit,
      'rental_days': order.rentalDays,
      'unit_price': 250000,
      'subtotal': order.jumlahUnit * order.rentalDays * 250000,
      'total_amount': order.jumlahUnit * order.rentalDays * 250000,
      'paid_amount': 0,
      'payment_status': 'Belum Lunas',
      'customer_name': order.namaClient,
      'customer_phone': order.nomorWhatsapp,
    });
    invoices.insert(0, inv);
    return order;
  }
}

void main() {
  group('UserProfile role helpers', () {
    test('identifies PIC Pemasangan correctly', () {
      const user = UserProfile('u-1', 'PIC Pemasangan', fullName: 'Budi');
      expect(user.isPic, isTrue);
      expect(user.isTechnician, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.canManageOrders, isTrue);
    });

    test('identifies Tim Service as Technician', () {
      const user = UserProfile('u-2', 'Tim Service', fullName: 'Salman');
      expect(user.isPic, isFalse);
      expect(user.isTechnician, isTrue);
      expect(user.canManageOrders, isFalse);
    });

    test('identifies Tim Pemasangan as Technician', () {
      const user = UserProfile('u-3', 'Tim Pemasangan', fullName: 'Agus');
      expect(user.isPic, isFalse);
      expect(user.isTechnician, isTrue);
      expect(user.canManageOrders, isFalse);
    });
  });

  group('InvoiceRecord model tests', () {
    test('calculates balance and status properly', () {
      const unpaidInv = InvoiceRecord(
        id: '1',
        orderanId: 'ORD-1',
        invoiceReference: 'INV-1',
        invoiceDate: '2026-09-10',
        dueDate: '2026-09-13',
        productName: 'Sewa Kipas',
        quantity: 2,
        rentalDays: 3,
        unitPrice: 250000,
        subtotal: 1500000,
        totalAmount: 1500000,
        paidAmount: 0,
        paymentStatus: 'Belum Lunas',
      );
      expect(unpaidInv.isUnpaid, isTrue);
      expect(unpaidInv.isPaid, isFalse);
      expect(unpaidInv.remainingAmount, 1500000);
      expect(InvoiceRecord.formatRupiah(unpaidInv.totalAmount), 'Rp 1.500.000');

      const dpInv = InvoiceRecord(
        id: '2',
        orderanId: 'ORD-2',
        invoiceReference: 'INV-2',
        invoiceDate: '2026-09-10',
        dueDate: '2026-09-13',
        productName: 'Sewa Kipas',
        quantity: 2,
        rentalDays: 3,
        unitPrice: 250000,
        subtotal: 1500000,
        totalAmount: 1500000,
        paidAmount: 500000,
        paymentStatus: 'DP',
      );
      expect(dpInv.isDp, isTrue);
      expect(dpInv.remainingAmount, 1000000);

      const paidInv = InvoiceRecord(
        id: '3',
        orderanId: 'ORD-3',
        invoiceReference: 'INV-3',
        invoiceDate: '2026-09-10',
        dueDate: '2026-09-13',
        productName: 'Sewa Kipas',
        quantity: 2,
        rentalDays: 3,
        unitPrice: 250000,
        subtotal: 1500000,
        totalAmount: 1500000,
        paidAmount: 1500000,
        paymentStatus: 'Lunas',
      );
      expect(paidInv.isPaid, isTrue);
      expect(paidInv.remainingAmount, 0);
    });
  });

  group('OrderanSewa H+1 Auto-completion logic', () {
    test('isDatePassed marks order passed when current date is past H+1', () {
      final pastOrder = OrderanSewa(
        id: 'ord-past',
        namaEvent: 'Acara Masa Lalu',
        tanggalPemasangan: DateTime.now().subtract(const Duration(days: 5)),
        catatanOrderan: '[SEWA_HARI:3]',
        statusOrderan: 'Terjadwal',
      );
      expect(pastOrder.isDatePassed, isTrue);
      expect(pastOrder.isPast, isTrue);
      expect(pastOrder.isUpcoming, isFalse);
    });

    test('isDatePassed is false when order is still ongoing or upcoming', () {
      final activeOrder = OrderanSewa(
        id: 'ord-active',
        namaEvent: 'Acara Sedang Jalan',
        tanggalPemasangan: DateTime.now().subtract(const Duration(hours: 4)),
        catatanOrderan: '[SEWA_HARI:2]',
        statusOrderan: 'Terjadwal',
      );
      expect(activeOrder.isDatePassed, isFalse);
      expect(activeOrder.isUpcoming, isTrue);
    });
  });

  group('PIC Navigation & UI integration', () {
    testWidgets('renders PIC Dashboard with Beranda, Orderan, Invoice tabs',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');

      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceHome(
            gateway: gateway,
            user: picUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PIC dashboard tabs should be present
      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Orderan'), findsWidgets);
      expect(find.text('Invoice'), findsWidgets);

      // Verify QR scanner button IS shown for PIC
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('PicHomeScreen shows event summary and quick action button',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PicHomeScreen(
              gateway: gateway,
              user: picUser,
              onOpenOrdersTab: () {},
              onOpenInvoicesTab: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Orderan\nBulan Ini'), findsOneWidget);
      expect(find.text('Total Order'), findsOneWidget);
      expect(find.text('Akan Datang'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Pameran Otomotif Akbar'), findsOneWidget);
    });

    testWidgets('InvoiceListScreen filters invoices by status',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceListScreen(
              gateway: gateway,
              user: picUser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daftar Invoice & Tagihan'), findsOneWidget);
      expect(find.text('INV/2026/09/10-001'), findsOneWidget);
      expect(find.text('INV/2026/09/05-002'), findsOneWidget);

      // Filter by 'Belum Lunas'
      await tester.tap(find.text('Belum Lunas').first);
      await tester.pumpAndSettle();

      expect(find.text('INV/2026/09/10-001'), findsOneWidget);
      expect(find.text('INV/2026/09/05-002'), findsNothing);
    });

    testWidgets('UpcomingOrdersScreen shows FAB to create order for PIC',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingOrdersScreen(
              gateway: gateway,
              user: picUser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orderan Baru'), findsOneWidget);
    });

    testWidgets('ScanScreen in read-only mode for PIC hides action buttons',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');
      final comp = Component.fromMap({
        'id': 'c-1',
        'nomor_stiker': 'KPL-001',
        'jenis_komponen': 'Kepala',
        'kondisi': 'OK',
        'boleh_dipakai': 'Ya',
        'fungsi_terganggu': 'Tidak Ada',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ScanScreen(
            gateway: gateway,
            user: picUser,
            readOnly: true,
            initialComponent: comp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only indicator should be present
      expect(find.text('Mode Pantau Status • Hanya Baca'), findsOneWidget);
      // Inspection / Servicing action buttons should NOT be present
      expect(find.text('Perbarui Kondisi Unit'), findsNothing);
      expect(find.text('Catat Servis Unit Ini'), findsNothing);
      // "Buka Detail" should be available
      expect(find.text('Buka Detail'), findsOneWidget);
    });

    testWidgets('ComponentDetailScreen in read-only mode hides edit buttons',
        (tester) async {
      final gateway = MockPicGateway();
      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');

      await tester.pumpWidget(
        MaterialApp(
          home: ComponentDetailScreen(
            gateway: gateway,
            id: 'c-1',
            user: picUser,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only lock indicator should be present
      expect(find.text('Mode Pantau Status • Hanya Baca'), findsOneWidget);
      // Action buttons to modify condition/service should be absent
      expect(find.text('Perbarui Kondisi'), findsNothing);
      expect(find.text('Catat Servis'), findsNothing);
    });
  });
}
