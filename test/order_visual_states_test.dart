import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_app_bar.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_button.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_multiline_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_search_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_state_view.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_status_badge.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/schedule/create_order_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_card.dart';
import 'package:mgrs_maintenance/features/schedule/unit_allocation_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const picUser = UserProfile('pic-1', 'PIC Pemasangan');

class OrderVisualGateway extends MaintenanceGateway {
  OrderVisualGateway({
    this.upcomingOutcomes = const <Object>[],
    this.createdOrder,
    this.createFailure,
    this.createCompleter,
    this.currentOrder,
    this.invoice,
    this.components = const <Map<String, Object?>>[],
    this.exactLookupResults = const <String, List<Map<String, Object?>>>{},
    this.usageHistory = const <String, List<Map<String, Object?>>>{},
    this.allocationFailure,
    this.allocationCompleter,
    this.statusFailure,
    this.statusCompleter,
    this.cancellationFailure,
    this.cancellationCompleter,
  });

  final List<Object> upcomingOutcomes;
  final OrderanSewa? createdOrder;
  final Object? createFailure;
  final Completer<OrderanSewa>? createCompleter;
  final OrderanSewa? currentOrder;
  final InvoiceRecord? invoice;
  final List<Map<String, Object?>> components;
  final Map<String, List<Map<String, Object?>>> exactLookupResults;
  final Map<String, List<Map<String, Object?>>> usageHistory;
  final Object? allocationFailure;
  final Completer<void>? allocationCompleter;
  final Object? statusFailure;
  final Completer<void>? statusCompleter;
  final Object? cancellationFailure;
  final Completer<void>? cancellationCompleter;

  int upcomingCalls = 0;
  final List<bool> upcomingForceRefresh = <bool>[];
  final List<Map<String, Object?>> orderPayloads = <Map<String, Object?>>[];
  final List<Map<String, Object?>> invoicePayloads = <Map<String, Object?>>[];
  final List<String> invoiceLookupIds = <String>[];
  final List<({String? kind, String? query})> componentRequests =
      <({String? kind, String? query})>[];
  final List<String> usageHistoryRequests = <String>[];
  final List<({String orderId, List<AllocatedUnit> units})> allocationSaves =
      <({String orderId, List<AllocatedUnit> units})>[];
  final List<({String orderId, String status})> statusUpdates =
      <({String orderId, String status})>[];
  final List<({String orderId, String reason, bool cancelInvoice})>
  cancellationRequests =
      <({String orderId, String reason, bool cancelInvoice})>[];

  @override
  Stream<void> get authChanges => const Stream<void>.empty();

  @override
  Future<UserProfile?> profile() async => picUser;

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
  }) async {
    upcomingCalls += 1;
    upcomingForceRefresh.add(forceRefresh);
    if (upcomingOutcomes.isEmpty) return const <OrderanSewa>[];
    final index = upcomingCalls <= upcomingOutcomes.length
        ? upcomingCalls - 1
        : upcomingOutcomes.length - 1;
    final outcome = upcomingOutcomes[index];
    if (outcome is Future<List<OrderanSewa>>) return outcome;
    if (outcome is List<OrderanSewa>) {
      return List<OrderanSewa>.from(outcome);
    }
    throw outcome;
  }

  @override
  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async => currentOrder;

  @override
  Future<OrderanSewa> createOrderWithInvoice(
    Map<String, Object?> orderData,
  ) async {
    orderPayloads.add(Map<String, Object?>.from(orderData));
    if (createCompleter != null) return createCompleter!.future;
    if (createFailure != null) throw createFailure!;
    return createdOrder ?? orderFixture(orderanId: 'ORD-SERVER-DEFAULT');
  }

  @override
  Future<InvoiceRecord> createInvoice(Map<String, Object?> payload) async {
    invoicePayloads.add(Map<String, Object?>.from(payload));
    return invoiceFixture();
  }

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async {
    invoiceLookupIds.add(orderanId);
    return invoice;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    bool forceRefresh = false,
  }) async {
    componentRequests.add((kind: kind, query: query));
    final normalizedQuery = query?.trim().toUpperCase();
    if (normalizedQuery != null &&
        exactLookupResults.containsKey(normalizedQuery)) {
      return exactLookupResults[normalizedQuery]!
          .map(Map<String, Object?>.from)
          .toList();
    }
    return components.where((component) {
      final componentKind = component['jenis_komponen']?.toString();
      final sticker = component['nomor_stiker']?.toString().toUpperCase() ?? '';
      final matchesKind = kind == null || componentKind == kind;
      final matchesQuery =
          normalizedQuery == null || sticker.contains(normalizedQuery);
      return matchesKind && matchesQuery;
    }).map(Map<String, Object?>.from).toList();
  }

  @override
  Future<Map<String, int>> fetchComponentUsageCounts({
    bool forceRefresh = false,
  }) async => const <String, int>{};

  @override
  Future<List<Map<String, Object?>>> fetchComponentOrderUsageHistory(
    String sticker, {
    bool forceRefresh = false,
  }) async {
    final normalized = sticker.trim().toUpperCase();
    usageHistoryRequests.add(normalized);
    return (usageHistory[normalized] ?? const <Map<String, Object?>>[])
        .map(Map<String, Object?>.from)
        .toList();
  }

  @override
  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {
    allocationSaves.add((
      orderId: orderanId,
      units: units.map(copyAllocatedUnit).toList(growable: false),
    ));
    if (allocationCompleter != null) await allocationCompleter!.future;
    if (allocationFailure != null) throw allocationFailure!;
  }

  @override
  Future<void> updateOrderStatus(String orderanId, String status) async {
    statusUpdates.add((orderId: orderanId, status: status));
    if (statusCompleter != null) await statusCompleter!.future;
    if (statusFailure != null) throw statusFailure!;
  }

  @override
  Future<void> cancelOrder(
    String orderanId, {
    required String reason,
    bool cancelInvoice = true,
  }) async {
    cancellationRequests.add((
      orderId: orderanId,
      reason: reason,
      cancelInvoice: cancelInvoice,
    ));
    if (cancellationCompleter != null) await cancellationCompleter!.future;
    if (cancellationFailure != null) throw cancellationFailure!;
  }
}

class FakeScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture> _barcodes =
      StreamController<BarcodeCapture>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream =>
      Stream<TorchState>.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream<double>.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(300, 220),
      numberOfCameras: 1,
    );
  }

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {
    if (!_barcodes.isClosed) await _barcodes.close();
  }
}

AllocatedUnit copyAllocatedUnit(AllocatedUnit unit) => AllocatedUnit(
  unitIndex: unit.unitIndex,
  kepalaSticker: unit.kepalaSticker,
  batangSticker: unit.batangSticker,
  tabungSticker: unit.tabungSticker,
);

OrderanSewa orderFixture({
  String id = '00000000-0000-0000-0000-000000000410',
  String orderanId = 'ORD-SERVER-410',
  String event = 'Pameran Peralatan Lapangan Nusantara',
  String status = 'Terjadwal',
  int units = 1,
  String? note = '[SEWA_HARI:2] [TGL_EVENT:2099-01-20]',
}) => OrderanSewa(
  id: id,
  orderanId: orderanId,
  namaEvent: event,
  namaClient: 'PT Operasional Lapangan Indonesia',
  alamat: 'Gedung Serbaguna Lapangan Utama, Jakarta Pusat',
  jumlahUnit: units,
  namaPic: 'Ratna Operasional',
  nomorWhatsapp: '081234567890',
  tanggalPemasangan: DateTime(2099, 1, 20),
  statusOrderan: status,
  catatanOrderan: note,
);

InvoiceRecord invoiceFixture({
  InvoicePaymentStatus status = InvoicePaymentStatus.unpaid,
  num paidAmount = 0,
}) => InvoiceRecord(
  id: 'invoice-410',
  orderanId: 'ORD-SERVER-410',
  invoiceReference: 'INV/2099/01/20-410',
  invoiceDate: '2099-01-20',
  dueDate: '2099-01-27',
  productName: 'Sewa blower',
  quantity: 1,
  rentalDays: 2,
  unitPrice: 250000,
  subtotal: 500000,
  totalAmount: 500000,
  paidAmount: paidAmount,
  paymentStatus: status,
);

Map<String, Object?> componentFixture(
  String sticker,
  String kind, {
  String condition = 'OK',
  String usable = 'Ya',
}) => <String, Object?>{
  'id': 'component-$sticker',
  'nomor_stiker': sticker,
  'jenis_komponen': kind,
  'kondisi': condition,
  'boleh_dipakai': usable,
};

Widget upcomingApp(OrderVisualGateway gateway) => MaterialApp(
  theme: maintenanceTheme(),
  home: UpcomingOrdersScreen(
    key: ValueKey<OrderVisualGateway>(gateway),
    gateway: gateway,
    user: picUser,
  ),
);

Widget createApp(OrderVisualGateway gateway) => MaterialApp(
  theme: maintenanceTheme(),
  home: CreateOrderScreen(
    key: ValueKey<OrderVisualGateway>(gateway),
    gateway: gateway,
    user: picUser,
  ),
);

Widget allocationApp(
  OrderVisualGateway gateway, {
  required OrderanSewa order,
  ValueChanged<List<AllocatedUnit>>? onChanged,
}) => MaterialApp(
  theme: maintenanceTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: UnitAllocationCard(
        key: ValueKey<OrderVisualGateway>(gateway),
        gateway: gateway,
        order: order,
        onAllocationChanged: onChanged,
      ),
    ),
  ),
);

Widget detailApp(
  OrderVisualGateway gateway, {
  required OrderanSewa order,
  UserProfile user = picUser,
}) => MaterialApp(
  theme: maintenanceTheme(),
  home: OrderDetailScreen(
    key: ValueKey<OrderVisualGateway>(gateway),
    order: order,
    orderId: order.id,
    gateway: gateway,
    user: user,
  ),
);

Future<void> pumpAt(
  WidgetTester tester,
  Widget widget, {
  double width = 390,
  double height = 844,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: widget,
    ),
  );
}

void expectUpcomingShell() {
  expect(find.text('Orderan'), findsOneWidget);
  expect(find.textContaining('Jadwal pemasangan'), findsOneWidget);
  expect(find.byType(MgrsSearchField), findsOneWidget);
  expect(find.text('Semua'), findsOneWidget);
  expect(find.text('Mendatang'), findsOneWidget);
  expect(find.text('Selesai'), findsOneWidget);
}

Finder createAction() => find.byWidgetPredicate(
  (widget) =>
      widget is MgrsButton &&
      widget.label.toLowerCase().contains('simpan') &&
      widget.label.toLowerCase().contains('terbitkan order'),
);

Finder createActionLabel() => find.textContaining(
  RegExp(r'^Simpan.*terbitkan order(an)?$', caseSensitive: false),
);

Finder cancellationAction() => find.byWidgetPredicate(
  (widget) =>
      widget is MgrsButton &&
      widget.label.toLowerCase().contains('batalkan order'),
);

Finder cancellationActionLabel() => find.textContaining(
  RegExp(r'^(Ya, )?Batalkan order(an)?$', caseSensitive: false),
);

List<EditableText> editableFields(WidgetTester tester) =>
    tester.widgetList<EditableText>(find.byType(EditableText)).toList();

Future<void> fillCreateDraft(
  WidgetTester tester, {
  String event = 'Festival Lapangan',
  String client = 'PT Karya Acara',
  String whatsapp = '081288877766',
  String address = 'Lapangan Utama Kota',
  String maps = 'https://maps.example/lapangan',
  String note = 'Perlu kabel 30 meter',
}) async {
  final fields = find.byType(EditableText);
  expect(fields, findsAtLeastNWidgets(6));
  for (final entry in <String>[
    event,
    client,
    whatsapp,
    address,
    maps,
    note,
  ].asMap().entries) {
    await tester.enterText(fields.at(entry.key), entry.value);
  }
}

Future<void> submitCreate(WidgetTester tester) async {
  final action = createActionLabel();
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump();
}

void installScannerFake(WidgetTester tester) {
  final original = MobileScannerPlatform.instance;
  MobileScannerPlatform.instance = FakeScannerPlatform();
  addTearDown(() => MobileScannerPlatform.instance = original);
}

Future<void> openScanner(WidgetTester tester) async {
  final action = find.textContaining(
    RegExp('scan barcode', caseSensitive: false),
  );
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(
    find.textContaining(RegExp('scan barcode komponen', caseSensitive: false)),
    findsOneWidget,
  );
}

Future<void> submitScannedCode(WidgetTester tester, String code) async {
  final dialogFields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(EditableText),
  );
  expect(dialogFields, findsOneWidget);
  await tester.enterText(dialogFields, code);
  final useAction = find.textContaining(
    RegExp(r'^Gunakan( kode)?$', caseSensitive: false),
  );
  expect(useAction, findsOneWidget);
  await tester.tap(useAction);
  await tester.pumpAndSettle();
}

Future<void> openCancellation(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert_rounded));
  await tester.pumpAndSettle();
  final menuItem = find.textContaining(
    RegExp(r'^Batalkan order$', caseSensitive: false),
  );
  expect(menuItem, findsOneWidget);
  await tester.tap(menuItem);
  await tester.pumpAndSettle();
}

void main() {
  group('Upcoming orders', () {
    testWidgets('loaded state keeps the order shell and shows server identity', (
      tester,
    ) async {
      final pending = Completer<List<OrderanSewa>>();
      final gateway = OrderVisualGateway(
        upcomingOutcomes: <Object>[pending.future],
      );

      await pumpAt(tester, upcomingApp(gateway));

      expectUpcomingShell();
      expect(find.byType(MgrsStateView), findsOneWidget);
      expect(find.textContaining('Memuat'), findsOneWidget);

      pending.complete(<OrderanSewa>[orderFixture()]);
      await tester.pumpAndSettle();

      expectUpcomingShell();
      expect(find.text('ORD-SERVER-410'), findsOneWidget);
      expect(
        find.text('00000000-0000-0000-0000-000000000410'),
        findsNothing,
      );
      expect(find.text('Pameran Peralatan Lapangan Nusantara'), findsOneWidget);
      expect(find.byType(MgrsStatusBadge), findsWidgets);
      expect(gateway.upcomingCalls, 1);
      expect(gateway.upcomingForceRefresh, <bool>[true]);
    });

    testWidgets('database empty replaces only the data region with recovery', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        upcomingOutcomes: const <Object>[<OrderanSewa>[]],
      );

      await pumpAt(tester, upcomingApp(gateway));
      await tester.pumpAndSettle();

      expectUpcomingShell();
      expect(find.byType(MgrsStateView), findsOneWidget);
      expect(
        find.textContaining(
          RegExp('belum ada orderan mendatang', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          RegExp('buat orderan baru', caseSensitive: false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('failure is sanitized, keeps the shell, and retry reloads data', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        upcomingOutcomes: <Object>[
          Exception('SQL secret: select * from orderan'),
          <OrderanSewa>[orderFixture(orderanId: 'ORD-RETRY-411')],
        ],
      );

      await pumpAt(tester, upcomingApp(gateway));
      await tester.pump();
      await tester.pump();

      expectUpcomingShell();
      expect(find.byType(MgrsStateView), findsOneWidget);
      expect(find.textContaining('SQL secret'), findsNothing);
      expect(
        find.textContaining(
          RegExp('daftar orderan gagal dimuat', caseSensitive: false),
        ),
        findsOneWidget,
      );
      final retry = find.text('Muat data terbaru');
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pumpAndSettle();

      expectUpcomingShell();
      expect(find.text('ORD-RETRY-411'), findsOneWidget);
      expect(gateway.upcomingCalls, 2);
      expect(gateway.upcomingForceRefresh, <bool>[true, true]);
    });

    testWidgets('loaded shell reflows at 320 px with 200 percent text', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        upcomingOutcomes: <Object>[
          <OrderanSewa>[
            orderFixture(
              event:
                  'Pameran Peralatan Lapangan dengan Nama Acara yang Panjang',
            ),
          ],
        ],
      );

      await pumpAt(
        tester,
        upcomingApp(gateway),
        width: 320,
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expectUpcomingShell();
      expect(find.text('ORD-SERVER-410'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Create order', () {
    testWidgets('idle form uses shared components and explains automatic invoice', (
      tester,
    ) async {
      final gateway = OrderVisualGateway();

      await pumpAt(tester, createApp(gateway));

      expect(find.byType(MgrsDetailAppBar), findsOneWidget);
      expect(find.text('Buat order'), findsOneWidget);
      expect(createAction(), findsOneWidget);
      expect(
        find.textContaining(RegExp('invoice.*otomatis', caseSensitive: false)),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(editableFields(tester).take(6).map((field) => field.controller.text),
          everyElement(isEmpty));
    });

    testWidgets('invalid submit shows inline errors and focuses the first field', (
      tester,
    ) async {
      final gateway = OrderVisualGateway();
      await pumpAt(tester, createApp(gateway));

      await submitCreate(tester);

      expect(find.text('Periksa kembali isian'), findsOneWidget);
      expect(find.text('Nama acara wajib diisi.'), findsOneWidget);
      expect(find.text('Nama klien wajib diisi.'), findsOneWidget);
      expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);
      expect(find.text('Alamat lokasi wajib diisi.'), findsOneWidget);
      expect(editableFields(tester).first.focusNode.hasFocus, isTrue);
      expect(gateway.orderPayloads, isEmpty);
    });

    testWidgets('pending submit locks the commit action and prevents duplicates', (
      tester,
    ) async {
      final pending = Completer<OrderanSewa>();
      final gateway = OrderVisualGateway(createCompleter: pending);
      await pumpAt(tester, createApp(gateway));
      await fillCreateDraft(tester);

      await submitCreate(tester);

      expect(gateway.orderPayloads, hasLength(1));
      final button = tester.widget<MgrsButton>(createAction());
      expect(button.loading, isTrue);
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(createAction());
      await tester.pump();
      expect(gateway.orderPayloads, hasLength(1));

      pending.complete(orderFixture(orderanId: 'ORD-SERVER-PENDING'));
      await tester.pumpAndSettle();
    });

    testWidgets('known failure keeps every draft value and shows safe recovery copy', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        createFailure: const AppFailure('invalid_input'),
      );
      await pumpAt(tester, createApp(gateway));
      await fillCreateDraft(tester);

      await submitCreate(tester);
      await tester.pumpAndSettle();

      expect(find.text('Order belum dapat disimpan'), findsOneWidget);
      expect(find.textContaining('Periksa kembali'), findsOneWidget);
      expect(find.textContaining('invalid_input'), findsNothing);
      expect(find.textContaining('AppFailure'), findsNothing);
      expect(
        editableFields(tester).take(6).map((field) => field.controller.text),
        <String>[
          'Festival Lapangan',
          'PT Karya Acara',
          '081288877766',
          'Lapangan Utama Kota',
          'https://maps.example/lapangan',
          'Perlu kabel 30 meter',
        ],
      );
      final button = tester.widget<MgrsButton>(createAction());
      expect(button.loading, isFalse);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('success reports server identity and preserves boolean navigation result', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        createdOrder: orderFixture(orderanId: 'ORD-SERVER-RETURNED-412'),
      );
      bool? routeResult;
      final app = MaterialApp(
        theme: maintenanceTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                routeResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CreateOrderScreen(
                      gateway: gateway,
                      user: picUser,
                    ),
                  ),
                );
              },
              child: const Text('Buka buat order'),
            ),
          ),
        ),
      );
      await pumpAt(tester, app);
      await tester.tap(find.text('Buka buat order'));
      await tester.pumpAndSettle();
      await fillCreateDraft(tester);

      await submitCreate(tester);
      await tester.pumpAndSettle();

      expect(routeResult, isTrue);
      expect(
        find.textContaining('ORD-SERVER-RETURNED-412'),
        findsOneWidget,
      );
      expect(
        gateway.orderPayloads.single['orderan_id'],
        isNot('ORD-SERVER-RETURNED-412'),
      );
    });

    testWidgets('submit preserves order payload and automatic-invoice semantics', (
      tester,
    ) async {
      final gateway = OrderVisualGateway(
        createdOrder: orderFixture(orderanId: 'ORD-SERVER-PAYLOAD-413'),
      );
      await pumpAt(tester, createApp(gateway));
      await fillCreateDraft(tester);
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pump();

      await submitCreate(tester);
      await tester.pumpAndSettle();

      final payload = gateway.orderPayloads.single;
      expect(
        payload.keys,
        unorderedEquals(<String>[
          'orderan_id',
          'tanggal_pemasangan',
          'nama_event',
          'nama_client',
          'alamat',
          'nomor_whatsapp',
          'link_gmaps',
          'jumlah_unit',
          'catatan_orderan',
          'status_orderan',
        ]),
      );
      expect(payload['orderan_id'], matches(RegExp(r'^ORD-\d{8}-\d{3}$')));
      expect(payload['nama_event'], 'Festival Lapangan');
      expect(payload['nama_client'], 'PT Karya Acara');
      expect(payload['alamat'], 'Lapangan Utama Kota');
      expect(payload['nomor_whatsapp'], '081288877766');
      expect(payload['link_gmaps'], 'https://maps.example/lapangan');
      expect(payload['jumlah_unit'], 2);
      expect(payload['status_orderan'], 'Terjadwal');
      final date = payload['tanggal_pemasangan'];
      expect(date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(
        payload['catatan_orderan'],
        'Perlu kabel 30 meter [SEWA_HARI:2] [TGL_EVENT:$date]',
      );
      expect(payload, isNot(contains('invoice_reference')));
      expect(payload, isNot(contains('total_amount')));
      expect(gateway.invoicePayloads, isEmpty);
      expect(find.byType(Checkbox), findsNothing);
      expect(createAction(), findsOneWidget);
    });
  });

  group('Unit allocation', () {
    testWidgets('component picker selection is visible and saved once', (
      tester,
    ) async {
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        components: <Map<String, Object?>>[
          componentFixture('K-100', 'Kepala'),
        ],
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-ALLOCATION-420'),
          onChanged: (units) => changes.add(
            units.map(copyAllocatedUnit).toList(growable: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kepala'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('K-100'));
      await tester.pumpAndSettle();

      expect(find.text('K-100'), findsOneWidget);
      expect(find.byType(MgrsStatusBadge), findsWidgets);
      expect(gateway.allocationSaves, hasLength(1));
      expect(gateway.allocationSaves.single.orderId, 'ORD-ALLOCATION-420');
      expect(gateway.allocationSaves.single.units.single.kepalaSticker, 'K-100');
      expect(changes, hasLength(1));
      expect(changes.single.single.kepalaSticker, 'K-100');
    });

    testWidgets('valid scanner match performs exact lookup then saves one snapshot', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: <String, List<Map<String, Object?>>>{
          'K-101': <Map<String, Object?>>[
            componentFixture('K-101', 'Kepala'),
          ],
        },
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-SCAN-421'),
          onChanged: (units) => changes.add(
            units.map(copyAllocatedUnit).toList(growable: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, ' k-101 ');

      expect(
        gateway.componentRequests.any(
          (request) => request.query?.trim().toUpperCase() == 'K-101',
        ),
        isTrue,
      );
      expect(gateway.usageHistoryRequests, contains('K-101'));
      expect(gateway.allocationSaves, hasLength(1));
      expect(gateway.allocationSaves.single.units.single.kepalaSticker, 'K-101');
      expect(changes, hasLength(1));
      expect(find.text('K-101'), findsOneWidget);
    });

    testWidgets('scanner rejects an exact sticker with the wrong component kind', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: <String, List<Map<String, Object?>>>{
          'K-BEDA': <Map<String, Object?>>[
            componentFixture('K-BEDA', 'Batang'),
          ],
        },
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-SCAN-422'),
          onChanged: (units) => changes.add(List<AllocatedUnit>.from(units)),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, 'K-BEDA');

      expect(
        find.textContaining(
          RegExp('terdaftar sebagai Batang.*bukan Kepala', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsOneWidget);
      expect(gateway.allocationSaves, isEmpty);
      expect(changes, isEmpty);
      expect(find.text('0 dari 1 unit lengkap'), findsOneWidget);
    });

    testWidgets('scanner rejects a component that is not found without mutation', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: const <String, List<Map<String, Object?>>>{
          'K-404': <Map<String, Object?>>[],
        },
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-SCAN-423'),
          onChanged: (units) => changes.add(List<AllocatedUnit>.from(units)),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, 'K-404');

      expect(
        find.textContaining(
          RegExp('komponen K-404 tidak ditemukan', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsOneWidget);
      expect(gateway.allocationSaves, isEmpty);
      expect(changes, isEmpty);
      expect(find.text('0 dari 1 unit lengkap'), findsOneWidget);
    });

    testWidgets('scanner rejects a duplicate already present in this order', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: <String, List<Map<String, Object?>>>{
          'K-001': <Map<String, Object?>>[
            componentFixture('K-001', 'Kepala'),
          ],
        },
      );
      final order = orderFixture(
        orderanId: 'ORD-SCAN-424',
        units: 2,
        note:
            '[SEWA_HARI:2] [TGL_EVENT:2099-01-20] [UNIT_ALOKASI: K-001+-+- | -+-+-]',
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: order,
          onChanged: (units) => changes.add(List<AllocatedUnit>.from(units)),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, 'K-001');

      expect(
        find.textContaining(
          RegExp('K-001.*sudah dipakai pada order ini', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(gateway.allocationSaves, isEmpty);
      expect(changes, isEmpty);
      expect(find.text('K-001'), findsOneWidget);
      expect(find.text('0 dari 2 unit lengkap'), findsOneWidget);
    });

    testWidgets('scanner rejects a component allocated to another active order', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: <String, List<Map<String, Object?>>>{
          'B-200': <Map<String, Object?>>[
            componentFixture('B-200', 'Batang'),
          ],
        },
        usageHistory: const <String, List<Map<String, Object?>>>{
          'B-200': <Map<String, Object?>>[
            <String, Object?>{
              'orderan_id': 'ORD-AKTIF-900',
              'status_orderan': 'Proses Pemasangan',
              'unit_index': 2,
              'role_slot': 'Batang',
            },
          ],
        },
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-SCAN-425'),
          onChanged: (units) => changes.add(List<AllocatedUnit>.from(units)),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, 'B-200');

      expect(gateway.usageHistoryRequests, <String>['B-200']);
      expect(
        find.textContaining('ORD-AKTIF-900'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          RegExp('masih dialokasikan', caseSensitive: false),
        ),
        findsOneWidget,
      );
      expect(gateway.allocationSaves, isEmpty);
      expect(changes, isEmpty);
      expect(find.text('0 dari 1 unit lengkap'), findsOneWidget);
    });

    testWidgets('scanner rejects a non-exact lookup result as request mismatch', (
      tester,
    ) async {
      installScannerFake(tester);
      final changes = <List<AllocatedUnit>>[];
      final gateway = OrderVisualGateway(
        exactLookupResults: <String, List<Map<String, Object?>>>{
          'T-300': <Map<String, Object?>>[
            componentFixture('T-301', 'Tabung'),
          ],
        },
      );
      await pumpAt(
        tester,
        allocationApp(
          gateway,
          order: orderFixture(orderanId: 'ORD-SCAN-426'),
          onChanged: (units) => changes.add(List<AllocatedUnit>.from(units)),
        ),
      );
      await tester.pumpAndSettle();

      await openScanner(tester);
      await submitScannedCode(tester, 'T-300');

      expect(
        find.textContaining(RegExp('tidak cocok', caseSensitive: false)),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsOneWidget);
      expect(gateway.allocationSaves, isEmpty);
      expect(changes, isEmpty);
      expect(find.text('0 dari 1 unit lengkap'), findsOneWidget);
    });

    testWidgets('completion confirmation sends server identity and waits for success', (
      tester,
    ) async {
      final pending = Completer<void>();
      final order = orderFixture(
        id: '00000000-0000-0000-0000-000000000427',
        orderanId: 'ORD-COMPLETE-427',
      );
      final gateway = OrderVisualGateway(
        currentOrder: order,
        statusCompleter: pending,
      );
      await pumpAt(
        tester,
        detailApp(gateway, order: order, user: picUser),
      );
      await tester.pumpAndSettle();

      final completeAction = find.textContaining(
        RegExp(r'^Tandai selesai$', caseSensitive: false),
      );
      expect(completeAction, findsOneWidget);
      await tester.tap(completeAction);
      await tester.pumpAndSettle();

      expect(find.textContaining('ORD-COMPLETE-427'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.textContaining(RegExp(r'1 unit', caseSensitive: false)),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Status order akan diubah menjadi Selesai.'),
        findsOneWidget,
      );
      expect(gateway.statusUpdates, isEmpty);

      final confirm = find.textContaining(
        RegExp(r'^(Setuju|Ya, Selesaikan)$', caseSensitive: false),
      );
      await tester.tap(confirm);
      await tester.pump();

      expect(
        gateway.statusUpdates,
        <({String orderId, String status})>[
          (orderId: 'ORD-COMPLETE-427', status: 'Selesai'),
        ],
      );
      expect(find.text('Selesai'), findsNothing);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Selesai'), findsWidgets);
    });
  });

  group('Order cancellation', () {
    testWidgets('empty reason stays focused with inline error and danger action', (
      tester,
    ) async {
      final order = orderFixture(orderanId: 'ORD-CANCEL-430');
      final gateway = OrderVisualGateway(currentOrder: order);
      await pumpAt(tester, detailApp(gateway, order: order));
      await tester.pumpAndSettle();

      await openCancellation(tester);

      expect(find.textContaining('ORD-CANCEL-430'), findsWidgets);
      await tester.tap(cancellationActionLabel());
      await tester.pump();

      expect(find.text('Alasan pembatalan minimal 3 karakter.'), findsOneWidget);
      expect(editableFields(tester).last.focusNode.hasFocus, isTrue);
      expect(gateway.cancellationRequests, isEmpty);
      expect(find.byType(MgrsMultilineField), findsOneWidget);
      final action = cancellationAction();
      expect(action, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(
        find.descendant(of: action, matching: find.byType(FilledButton)),
      );
      expect(
        filledButton.style?.backgroundColor?.resolve(const <WidgetState>{}),
        MgrsColors.danger,
      );

    });

    testWidgets('unpaid invoice option defaults on and transition waits for backend', (
      tester,
    ) async {
      final pending = Completer<void>();
      final order = orderFixture(
        id: '00000000-0000-0000-0000-000000000431',
        orderanId: 'ORD-CANCEL-431',
      );
      final gateway = OrderVisualGateway(
        currentOrder: order,
        invoice: invoiceFixture(),
        cancellationCompleter: pending,
      );
      await pumpAt(tester, detailApp(gateway, order: order));
      await tester.pumpAndSettle();

      await openCancellation(tester);

      const option = 'Batalkan invoice yang belum dibayar';
      expect(find.text(option), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(EditableText),
        ),
        '  Acara dibatalkan oleh klien  ',
      );
      await tester.tap(cancellationActionLabel());
      await tester.pump();

      expect(
        gateway.cancellationRequests,
        <({String orderId, String reason, bool cancelInvoice})>[
          (
            orderId: '00000000-0000-0000-0000-000000000431',
            reason: 'Acara dibatalkan oleh klien',
            cancelInvoice: true,
          ),
        ],
      );
      expect(find.text('Dibatalkan'), findsNothing);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsWidgets);
      expect(
        find.textContaining('Acara dibatalkan oleh klien'),
        findsOneWidget,
      );
    });

    testWidgets('unpaid invoice selection controls cancelInvoice payload', (
      tester,
    ) async {
      final order = orderFixture(orderanId: 'ORD-CANCEL-432');
      final gateway = OrderVisualGateway(
        currentOrder: order,
        invoice: invoiceFixture(),
      );
      await pumpAt(tester, detailApp(gateway, order: order));
      await tester.pumpAndSettle();
      await openCancellation(tester);

      const option = 'Batalkan invoice yang belum dibayar';
      await tester.tap(find.text(option));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(EditableText),
        ),
        'Invoice tetap diperlukan klien',
      );
      await tester.tap(cancellationActionLabel());
      await tester.pumpAndSettle();

      expect(gateway.cancellationRequests, hasLength(1));
      expect(gateway.cancellationRequests.single.cancelInvoice, isFalse);
      expect(gateway.cancellationRequests.single.reason,
          'Invoice tetap diperlukan klien');
    });

    testWidgets('invoice option is absent without a truly unpaid invoice', (
      tester,
    ) async {
      final cases = <InvoiceRecord?>[
        null,
        invoiceFixture(
          status: InvoicePaymentStatus.paid,
          paidAmount: 500000,
        ),
        invoiceFixture(
          status: InvoicePaymentStatus.partial,
          paidAmount: 100000,
        ),
        invoiceFixture(status: InvoicePaymentStatus.cancelled),
      ];

      for (final invoice in cases) {
        final order = orderFixture(
          id: 'order-${invoice?.paymentStatus.name ?? 'none'}',
          orderanId: 'ORD-${invoice?.paymentStatus.name ?? 'NONE'}',
        );
        final gateway = OrderVisualGateway(
          currentOrder: order,
          invoice: invoice,
        );
        await pumpAt(tester, detailApp(gateway, order: order));
        await tester.pumpAndSettle();
        await openCancellation(tester);

        expect(
          find.text('Batalkan invoice yang belum dibayar'),
          findsNothing,
        );
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byType(MgrsMultilineField), findsOneWidget);

        final safeAction = find.textContaining(
          RegExp(r'^(Batal|Kembali)$', caseSensitive: false),
        );
        expect(safeAction, findsOneWidget);
        await tester.tap(safeAction);
        await tester.pumpAndSettle();
      }
    });
  });
}
