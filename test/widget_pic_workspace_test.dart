import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/home/pic_home_screen.dart';
import 'package:mgrs_maintenance/features/invoices/create_invoice_dialog.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/invoices/quick_payment_dialog.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';

class _FakePicGateway extends MaintenanceGateway {
  _FakePicGateway({
    this.orders = const [],
    this.invoices = const [],
    this.fetchOrdersError,
  });

  List<OrderanSewa> orders;
  List<InvoiceRecord> invoices;
  Object? fetchOrdersError;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async => null;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (fetchOrdersError != null) throw fetchOrdersError!;
    return orders;
  }

  @override
  Future<List<InvoiceRecord>> fetchInvoices({
    bool forceRefresh = false,
  }) async {
    return invoices;
  }
  @override
  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (fetchOrdersError != null) throw fetchOrdersError!;
    return orders.firstWhere(
      (o) => o.id == id || o.orderanId == id,
      orElse: () => OrderanSewa(
        id: id,
        namaEvent: 'Fallback Event',
        namaClient: 'Fallback Client',
      ),
    );
  }

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async {
    for (final inv in invoices) {
      if (inv.orderanId == orderanId || inv.id == orderanId) return inv;
    }
    return null;
  }
}

const _picUser = UserProfile(
  'pic-user-1',
  'PIC Pemasangan',
  fullName: 'PIC Test User',
);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: maintenanceTheme(),
    home: child,
  );
}

void main() {
  testWidgets('PIC empty order state is explicit', (tester) async {
    final gateway = _FakePicGateway(orders: const []);
    await tester.pumpWidget(
      _wrap(
        PicHomeScreen(
          gateway: gateway,
          user: _picUser,
          onOpenOrdersTab: () {},
          onOpenInvoicesTab: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada orderan'), findsOneWidget);
    expect(find.text('24 mesin aktif dipantau'), findsNothing);
  });

  testWidgets('invoice controls remain at least 48dp', (tester) async {
    final record = InvoiceRecord(
      id: 'inv-test-1',
      orderanId: 'ord-123',
      invoiceReference: 'INV/2026/09/001',
      customerName: 'PT Mandiri Sukses',
      productName: 'Rental Blower Industrial',
      quantity: 2,
      unitPrice: 250000,
      subtotal: 1500000,
      totalAmount: 1500000,
      paidAmount: 500000,
      paymentStatus: InvoicePaymentStatus.partial,
      invoiceDate: '2026-09-13',
      dueDate: '2026-09-20',
      rentalDays: 3,
      invoiceSource: 'automatic',
    );

    final gateway = _FakePicGateway(invoices: [record]);
    await tester.pumpWidget(
      _wrap(
        InvoiceListScreen(
          gateway: gateway,
          user: _picUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final delete = find.byTooltip('Hapus invoice');
    expect(delete, findsOneWidget);
    expect(tester.getSize(delete).shortestSide, greaterThanOrEqualTo(48));
  });

  testWidgets('PIC upcoming orders screen renders honest list without bento claims',
      (tester) async {
    final order = OrderanSewa(
      id: 'ord-101',
      namaEvent: 'Konser Musik Nasional',
      namaClient: 'Promotor Event',
      tanggalPemasangan: DateTime.now().add(const Duration(days: 2)),
      statusOrderan: 'Confirmed',
    );

    final gateway = _FakePicGateway(orders: [order]);
    await tester.pumpWidget(
      _wrap(
        UpcomingOrdersScreen(
          gateway: gateway,
          user: _picUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konser Musik Nasional'), findsOneWidget);
    expect(find.textContaining('Promotor Event'), findsOneWidget);
    expect(find.text('24 mesin aktif dipantau'), findsNothing);
  });

  testWidgets('Upcoming orders shows honest error state with retry',
      (tester) async {
    final gateway = _FakePicGateway(
      fetchOrdersError: Exception('Koneksi timeout'),
    );
    await tester.pumpWidget(
      _wrap(
        UpcomingOrdersScreen(
          gateway: gateway,
          user: _picUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
    expect(
      find.text('Data belum dapat dimuat'),
      findsOneWidget,
    );

    // Verify retry can be tapped
    gateway.fetchOrdersError = null;
    gateway.orders = [
      OrderanSewa(
        id: 'ord-102',
        namaEvent: 'Pameran Otomotif',
        statusOrderan: 'Terjadwal',
      )
    ];
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Pameran Otomotif'), findsOneWidget);
  });

  testWidgets('PIC order detail does not expose field technician navigation',
      (tester) async {
    final order = OrderanSewa(
      id: 'ord-103',
      namaEvent: 'Resepsi Pernikahan',
      namaClient: 'Keluarga Budi',
      alamat: 'Gedung Serbaguna',
      statusOrderan: 'Terjadwal',
      jumlahUnit: 2,
    );

    final gateway = _FakePicGateway(orders: [order]);
    await tester.pumpWidget(
      _wrap(
        OrderDetailScreen(
          order: order,
          gateway: gateway,
          user: _picUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Resepsi Pernikahan'), findsOneWidget);
    expect(find.text('Invoice Terkait'), findsOneWidget);
    // Field maintenance technician actions must not exist for PIC
    expect(find.text('Catat Pemeriksaan'), findsNothing);
    expect(find.text('Catat Servis'), findsNothing);
  });

  testWidgets('Quick payment dialog submit control has at least 48dp height',
      (tester) async {
    final invoice = InvoiceRecord(
      id: 'inv-101',
      invoiceReference: 'INV/2026/09/101',
      customerName: 'Klien Test',
      productName: 'Rental Blower Industrial',
      quantity: 1,
      unitPrice: 500000,
      subtotal: 500000,
      totalAmount: 500000,
      paidAmount: 0,
      paymentStatus: InvoicePaymentStatus.unpaid,
      invoiceDate: '2026-09-13',
      dueDate: '2026-09-20',
      rentalDays: 1,
      invoiceSource: 'manual',
    );

    final gateway = _FakePicGateway(invoices: [invoice]);
    await tester.pumpWidget(
      _wrap(
        QuickPaymentDialog(
          invoice: invoice,
          gateway: gateway,
          onPaymentUpdated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Simpan Status Pembayaran');
    expect(saveButton, findsOneWidget);
    expect(tester.getSize(saveButton).height, greaterThanOrEqualTo(48));

    final closeBtn = find.byTooltip('Tutup');
    expect(closeBtn, findsOneWidget);
    expect(tester.getSize(closeBtn).shortestSide, greaterThanOrEqualTo(48));
  });

  testWidgets('Create invoice dialog submit control has at least 48dp height',
      (tester) async {
    final gateway = _FakePicGateway(orders: const []);
    await tester.pumpWidget(
      _wrap(
        CreateInvoiceDialog(
          gateway: gateway,
          onCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitBtn = find.widgetWithText(FilledButton, 'Buat dan Simpan Invoice');
    expect(submitBtn, findsOneWidget);
    expect(tester.getSize(submitBtn).height, greaterThanOrEqualTo(48));
  });
}


