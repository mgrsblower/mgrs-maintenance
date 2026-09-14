import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/invoices/widgets/invoice_card.dart';
import 'package:mgrs_maintenance/features/invoices/widgets/invoice_list_shell.dart';

const _user = UserProfile('pic-1', 'PIC Pemasangan');

class _InvoiceGateway extends MaintenanceGateway {
  _InvoiceGateway(this.outcomes);

  final List<Object> outcomes;
  final List<bool> forceRefreshCalls = <bool>[];
  var calls = 0;

  @override
  Stream<void> get authChanges => const Stream<void>.empty();

  @override
  Future<UserProfile?> profile() async => _user;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<List<InvoiceRecord>> fetchInvoices({bool forceRefresh = false}) async {
    forceRefreshCalls.add(forceRefresh);
    final index = calls < outcomes.length ? calls : outcomes.length - 1;
    calls += 1;
    final outcome = outcomes[index];
    if (outcome is Future<List<InvoiceRecord>>) return outcome;
    if (outcome is List<InvoiceRecord>) return outcome;
    throw outcome;
  }
}

InvoiceRecord _invoice(
  String id,
  InvoicePaymentStatus status, {
  String source = 'automatic',
  String customer = 'CV Maju Jaya',
  num paid = 0,
}) {
  return InvoiceRecord(
    id: id,
    orderanId: 'ORD-$id',
    invoiceReference: 'INV-$id',
    invoiceDate: '2026-09-15',
    dueDate: '2026-09-18',
    productName: 'Sewa Blower',
    quantity: 2,
    rentalDays: 2,
    unitPrice: 250000,
    subtotal: 1000000,
    totalAmount: 1000000,
    paidAmount: paid,
    paymentStatus: status,
    customerName: customer,
    invoiceSource: source,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _InvoiceGateway gateway, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: InvoiceListScreen(
        key: ValueKey<_InvoiceGateway>(gateway),
        gateway: gateway,
        user: _user,
      ),
    ),
  );
}

void _expectStableShell() {
  expect(find.text('Daftar Invoice'), findsOneWidget);
  expect(find.byKey(const Key('invoice-create-action')), findsOneWidget);
  expect(find.text('Order Sewa'), findsOneWidget);
  expect(find.text('Reimbursement'), findsOneWidget);
  expect(find.byKey(const Key('invoice-search-field')), findsOneWidget);
  expect(find.text('Semua'), findsOneWidget);
  expect(find.text('Belum Bayar'), findsWidgets);
  expect(find.text('Sebagian'), findsWidgets);
  expect(find.text('Lunas'), findsWidgets);
}

void main() {
  group('InvoiceListShell', () {
    testWidgets('keeps navigation controls visible while body changes', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: InvoiceListShell(
            sourceFilter: InvoiceSourceFilter.automatic,
            paymentFilter: null,
            searchController: controller,
            onSourceChanged: (_) {},
            onPaymentChanged: (_) {},
            onSearchChanged: (_) {},
            onCreate: () {},
            body: const Text('BODY-ONLY'),
          ),
        ),
      );

      _expectStableShell();
      expect(find.text('BODY-ONLY'), findsOneWidget);
    });
  });

  group('Invoice list states', () {
    testWidgets('shows stable shell during loading then loaded cards', (
      tester,
    ) async {
      final pending = Completer<List<InvoiceRecord>>();
      final gateway = _InvoiceGateway(<Object>[pending.future]);
      await _pumpScreen(tester, gateway);
      await tester.pump();

      _expectStableShell();
      expect(find.text('Memuat invoice...'), findsOneWidget);

      pending.complete(<InvoiceRecord>[
        _invoice('UNPAID', InvoicePaymentStatus.unpaid),
        _invoice('PARTIAL', InvoicePaymentStatus.partial, paid: 300000),
        _invoice('PAID', InvoicePaymentStatus.paid, paid: 1000000),
      ]);
      await tester.pumpAndSettle();

      _expectStableShell();
      expect(find.byType(InvoiceCard), findsWidgets);
      expect(find.text('Belum Bayar'), findsWidgets);
    });

    testWidgets('renders unpaid, partial, and paid card variants', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                for (final invoice in <InvoiceRecord>[
                  _invoice('UNPAID', InvoicePaymentStatus.unpaid),
                  _invoice(
                    'PARTIAL',
                    InvoicePaymentStatus.partial,
                    paid: 300000,
                  ),
                  _invoice('PAID', InvoicePaymentStatus.paid, paid: 1000000),
                ])
                  InvoiceCard(
                    invoice: invoice,
                    onPayment: () {},
                    onOpen: () {},
                    onDelete: () {},
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(InvoiceCard), findsNWidgets(3));
      expect(find.text('Belum Bayar'), findsOneWidget);
      expect(find.text('Sebagian'), findsOneWidget);
      expect(find.text('Lunas'), findsWidgets);
    });

    testWidgets('distinguishes database empty from filtered no-results', (
      tester,
    ) async {
      await _pumpScreen(tester, _InvoiceGateway(<Object>[<InvoiceRecord>[]]));
      await tester.pumpAndSettle();

      _expectStableShell();
      expect(find.text('Belum ada invoice'), findsOneWidget);

      await _pumpScreen(
        tester,
        _InvoiceGateway(<Object>[
          <InvoiceRecord>[_invoice('ONE', InvoicePaymentStatus.unpaid)],
        ]),
      );
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byKey(const Key('invoice-search-field')),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'tidak ditemukan');
      await tester.pumpAndSettle();

      _expectStableShell();
      expect(find.text('Pencarian tidak ditemukan'), findsOneWidget);
      expect(find.textContaining('tidak ditemukan'), findsWidgets);
    });

    testWidgets('sanitizes failures and retry forces refresh', (tester) async {
      final gateway = _InvoiceGateway(<Object>[
        Exception('relation invoices does not exist SQLSTATE 42P01'),
        <InvoiceRecord>[_invoice('RECOVERED', InvoicePaymentStatus.paid)],
      ]);
      await _pumpScreen(tester, gateway);
      await tester.pumpAndSettle();

      _expectStableShell();
      expect(find.text('Invoice gagal dimuat'), findsOneWidget);
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);

      await tester.tap(find.text('Muat data terbaru'));
      await tester.pumpAndSettle();
      expect(gateway.forceRefreshCalls, <bool>[false, true]);
      expect(find.text('INV-RECOVERED'), findsOneWidget);
    });

    testWidgets('applies source, payment, and search filters', (tester) async {
      final gateway = _InvoiceGateway(<Object>[
        <InvoiceRecord>[
          _invoice('AUTO-U', InvoicePaymentStatus.unpaid),
          _invoice('AUTO-P', InvoicePaymentStatus.paid, paid: 1000000),
          _invoice(
            'MANUAL',
            InvoicePaymentStatus.partial,
            source: 'manual_reimbursement',
            customer: 'PT Manual',
            paid: 200000,
          ),
        ],
      ]);
      await _pumpScreen(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text('INV-AUTO-U'), findsOneWidget);
      expect(find.text('INV-MANUAL'), findsNothing);

      await tester.ensureVisible(find.text('Lunas').first);
      await tester.tap(find.text('Lunas').first);
      await tester.pump();
      expect(find.text('INV-AUTO-P'), findsOneWidget);
      expect(find.text('INV-AUTO-U'), findsNothing);

      await tester.ensureVisible(find.text('Reimbursement'));
      await tester.tap(find.text('Reimbursement'));
      await tester.ensureVisible(find.text('Semua'));
      await tester.tap(find.text('Semua'));
      await tester.enterText(find.byType(TextField), 'manual');
      await tester.pump();
      expect(find.text('INV-MANUAL'), findsOneWidget);
    });

    testWidgets('create action opens the invoice form', (tester) async {
      await _pumpScreen(tester, _InvoiceGateway(<Object>[<InvoiceRecord>[]]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invoice-create-action')));
      await tester.pumpAndSettle();
      expect(find.text('Buat Invoice Baru'), findsOneWidget);
    });

    testWidgets('fits 320 px at 200 percent text scale', (tester) async {
      await _pumpScreen(
        tester,
        _InvoiceGateway(<Object>[
          <InvoiceRecord>[_invoice('NARROW', InvoicePaymentStatus.partial)],
        ]),
        size: const Size(320, 720),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      _expectStableShell();
    });
  });
}
