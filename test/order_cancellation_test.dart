import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

class MockCancellationGateway extends MaintenanceGateway {
  OrderanSewa order;
  InvoiceRecord? invoice;
  bool cancelOrderCalled = false;
  String? lastInvoiceOrderId;
  String? lastCancelledId;
  String? lastReason;
  bool? lastCancelInvoice;

  MockCancellationGateway({
    required this.order,
    this.invoice,
  });

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
  Future<OrderanSewa?> fetchOrderDetail(
    String orderanId, {
    bool forceRefresh = false,
  }) async => order;

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async {
    lastInvoiceOrderId = orderanId;
    return invoice;
  }

  @override
  Future<void> cancelOrder(
    String orderanId, {
    required String reason,
    bool cancelInvoice = true,
  }) async {
    cancelOrderCalled = true;
    lastCancelledId = orderanId;
    lastReason = reason;
    lastCancelInvoice = cancelInvoice;

    final currentNote = order.catatanOrderan ?? '';
    final cancelTag = '[BATAL: ${reason.trim()}]';
    final updatedNote = currentNote.isNotEmpty ? '$currentNote\n$cancelTag' : cancelTag;

    order = order.copyWith(
      statusOrderan: 'Dibatalkan',
      catatanOrderan: updatedNote,
    );

    if (cancelInvoice && invoice != null) {
      if (invoice!.paymentStatus == InvoicePaymentStatus.unpaid || invoice!.paidAmount <= 0) {
        invoice = null;
      }
    }
  }

  @override
  Future<void> updateOrderStatus(String orderanId, String status) async {
    order = order.copyWith(statusOrderan: status);
  }
}

void main() {
  group('Order Model Cancellation Tests', () {
    test('isCancelled and isCompletedOrCancelled recognize Dibatalkan status', () {
      final order = OrderanSewa(
        id: 'ord-1b',
        orderanId: 'ORD-2026-001b',
        namaEvent: 'Konser Musik',
        statusOrderan: 'Dibatalkan',
        catatanOrderan: '[SEWA_HARI:2] [BATAL: Cuaca buruk badai]',
      );

      expect(order.isCancelled, isTrue);
      expect(order.isCompletedOrCancelled, isTrue);
      expect(order.isUpcoming, isFalse);
      expect(order.cancellationReason, equals('Cuaca buruk badai'));
      expect(order.cleanNote, isEmpty);
    });

    test('cancellationReason returns null when no tag present', () {
      final order = OrderanSewa(
        id: 'ord-2',
        orderanId: 'ORD-2026-002',
        namaEvent: 'Pameran Seni',
        statusOrderan: 'Terjadwal',
        catatanOrderan: 'Catatan penting sewa kipas',
      );

      expect(order.isCancelled, isFalse);
      expect(order.cancellationReason, isNull);
      expect(order.cleanNote, equals('Catatan penting sewa kipas'));
    });
  });

  group('Invoice Model Cancellation Tests', () {
    test('InvoicePaymentStatus.cancelled serializes and deserializes', () {
      expect(InvoicePaymentStatus.cancelled.toJson(), equals('cancelled'));
      expect(InvoicePaymentStatus.cancelled.label, equals('Dibatalkan'));
      expect(InvoicePaymentStatus.fromJson('cancelled'), equals(InvoicePaymentStatus.cancelled));
      expect(InvoicePaymentStatus.fromJson('batal'), equals(InvoicePaymentStatus.cancelled));
      expect(InvoicePaymentStatus.fromJson('dibatalkan'), equals(InvoicePaymentStatus.cancelled));
    });

    test('InvoiceRecord isCancelled flag and calculation', () {
      const inv = InvoiceRecord(
        id: 'inv-1',
        orderanId: 'ORD-2026-001',
        invoiceReference: 'INV/2026/09/11-001',
        invoiceDate: '2026-09-11',
        dueDate: '2026-09-14',
        productName: 'Blower Sewa',
        quantity: 2,
        rentalDays: 1,
        unitPrice: 250000,
        subtotal: 500000,
        totalAmount: 500000,
        paidAmount: 0,
        paymentStatus: InvoicePaymentStatus.cancelled,
      );

      expect(inv.isCancelled, isTrue);
      expect(inv.isUnpaid, isFalse);
      expect(inv.isPaid, isFalse);
      expect(inv.isDp, isFalse);
      expect(inv.paymentStatusDisplay, equals('Dibatalkan'));
    });
  });

  group('OrderDetailScreen Cancellation Flow Widget Tests', () {
    testWidgets('PIC can cancel order with reason and unpaid invoice is auto-cancelled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final initialOrder = OrderanSewa(
        id: '00000000-0000-0000-0000-000000000010',
        orderanId: 'ORD-20260911-010',
        namaEvent: 'Festival Kuliner Nusantara',
        namaClient: 'PT Rasa Kuliner',
        alamat: 'Lapangan Banteng, Jakarta Pusat',
        jumlahUnit: 5,
        tanggalPemasangan: DateTime.now().add(const Duration(days: 2)),
        statusOrderan: 'Terjadwal',
        catatanOrderan: '[SEWA_HARI:2]',
      );

      final initialInvoice = const InvoiceRecord(
        id: 'inv-10',
        orderanId: 'ORD-20260911-010',
        invoiceReference: 'INV/2026/09/11-010',
        invoiceDate: '2026-09-11',
        dueDate: '2026-09-15',
        productName: 'Sewa Blower',
        quantity: 5,
        rentalDays: 2,
        unitPrice: 250000,
        subtotal: 2500000,
        totalAmount: 2500000,
        paidAmount: 0,
        paymentStatus: InvoicePaymentStatus.unpaid,
      );

      final mockGateway = MockCancellationGateway(
        order: initialOrder,
        invoice: initialInvoice,
      );

      const picUser = UserProfile('u-1', 'PIC Pemasangan'); // canManageOrders = true

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailScreen(
            order: initialOrder,
            gateway: mockGateway,
            user: picUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active order header and bottom "Tandai Selesai" button
      expect(find.text('ORD-20260911-010'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Tandai Selesai'), findsOneWidget);

      // Verify three-dots menu button is present
      final moreButton = find.byIcon(Icons.more_vert_rounded);
      expect(moreButton, findsOneWidget);

      // Tap three-dots menu
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Expect "Batalkan Order" item
      final cancelMenuItem = find.text('Batalkan Order');
      expect(cancelMenuItem, findsOneWidget);

      // Tap "Batalkan Order"
      await tester.tap(cancelMenuItem);
      await tester.pumpAndSettle();

      // Verify cancellation dialog opened
      expect(find.text('Batalkan Orderan?'), findsOneWidget);
      expect(find.textContaining('Invoice terkait (INV/2026/09/11-010) yang belum dibayar akan otomatis dibatalkan'), findsOneWidget);

      // Try submitting without reason (validation error)
      final submitButton = find.widgetWithText(FilledButton, 'Ya, Batalkan Order');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.text('Alasan pembatalan minimal 3 karakter.'), findsOneWidget);

      // Enter valid reason
      final reasonInput = find.byType(TextFormField);
      await tester.enterText(reasonInput, 'Penyelenggara membatalkan karena kendala teknis');
      await tester.pumpAndSettle();

      // Submit cancellation
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify gateway call
      expect(mockGateway.cancelOrderCalled, isTrue);
      expect(
        mockGateway.lastInvoiceOrderId,
        equals('00000000-0000-0000-0000-000000000010'),
      );
      expect(
        mockGateway.lastCancelledId,
        equals('00000000-0000-0000-0000-000000000010'),
      );
      expect(mockGateway.lastReason, equals('Penyelenggara membatalkan karena kendala teknis'));
      expect(mockGateway.lastCancelInvoice, isTrue);

      // Verify UI updated to "Dibatalkan"
      expect(find.text('Dibatalkan'), findsAtLeastNWidgets(1));
      expect(find.text('Orderan Ini Telah Dibatalkan'), findsOneWidget);
      expect(find.textContaining('Alasan: Penyelenggara membatalkan karena kendala teknis'), findsOneWidget);

      // Bottom "Tandai Selesai" button should now be gone because order is cancelled
      expect(find.text('Tandai Selesai'), findsNothing);

      // Three-dots menu should no longer appear on a cancelled order
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    testWidgets('Cancellation dialog displays warning banner when invoice has recorded payment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final initialOrder = OrderanSewa(
        id: 'ord-11',
        orderanId: 'ORD-20260911-011',
        namaEvent: 'Pesta Pernikahan Outdoor',
        namaClient: 'Bapak Hendra',
        jumlahUnit: 3,
        tanggalPemasangan: DateTime.now().add(const Duration(days: 1)),
        statusOrderan: 'Terjadwal',
      );

      final dpInvoice = const InvoiceRecord(
        id: 'inv-11',
        orderanId: 'ORD-20260911-011',
        invoiceReference: 'INV/2026/09/11-011',
        invoiceDate: '2026-09-11',
        dueDate: '2026-09-15',
        productName: 'Sewa Blower',
        quantity: 3,
        rentalDays: 1,
        unitPrice: 250000,
        subtotal: 750000,
        totalAmount: 750000,
        paidAmount: 300000, // Partial DP
        paymentStatus: InvoicePaymentStatus.partial,
      );

      final mockGateway = MockCancellationGateway(
        order: initialOrder,
        invoice: dpInvoice,
      );

      const picUser = UserProfile('u-1', 'PIC Pemasangan');

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailScreen(
            order: initialOrder,
            gateway: mockGateway,
            user: picUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open three-dots menu and tap cancel
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batalkan Order'));
      await tester.pumpAndSettle();

      // Should show the amber warning banner regarding the DP
      expect(find.textContaining('Perhatian: Invoice memiliki pembayaran tercatat sebesar Rp 300.000'), findsOneWidget);
    });
  });
}
