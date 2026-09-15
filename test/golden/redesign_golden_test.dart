import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/auth/login_screen.dart';
import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
import 'package:mgrs_maintenance/features/home/home_screen.dart';
import 'package:mgrs_maintenance/features/home/pic_home_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';
import 'package:mgrs_maintenance/features/scan/scan_screen.dart';
import 'package:mgrs_maintenance/features/scan/scan_state.dart';
import 'package:mgrs_maintenance/features/schedule/component_picker_sheet.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';

import '../helpers/test_viewport.dart';

const _goldenRoot = Key('redesign-golden-root');
const _serviceUser = UserProfile(
  'service-1',
  'Tim Service',
  fullName: 'Budi Teknisi',
  username: 'budi',
);
const _picUser = UserProfile(
  'pic-1',
  'PIC Pemasangan',
  fullName: 'Sari PIC',
  username: 'sari',
);

const _componentRow = <String, Object?>{
  'id': 'component-1',
  'code': 'KPL-2026-084',
  'kind': 'Kepala',
  'condition': 'OK',
  'usable': 'Ya',
  'impairedFunction': 'Tidak Ada',
  'note': 'Siap digunakan',
  'version': '1',
  'lastCheckingAt': '2026-09-14T10:00:00Z',
  'lastServiceAt': '2026-09-10T10:00:00Z',
  'nomor_stiker': 'KPL-2026-084',
  'jenis_komponen': 'Kepala',
  'kondisi': 'OK',
  'boleh_dipakai': 'Ya',
  'fungsi_terganggu': 'Tidak Ada',
  'keterangan': 'Siap digunakan',
};

const _order = OrderanSewa(
  id: 'order-1',
  orderanId: 'ORD-2026-088',
  namaEvent: 'Festival Musik Senayan',
  namaClient: 'PT Maju Bersama',
  alamat: 'Parkir Timur Senayan, Jakarta',
  jumlahUnit: 4,
  namaPic: 'Rudi Hartono',
  nomorWhatsapp: '081234567890',
  linkGmaps: 'https://maps.google.com/?q=Senayan',
  tanggalPemasangan: null,
  statusOrderan: 'Terjadwal',
  catatanOrderan: 'Pasang sebelum pukul 10.00 [SEWA_HARI:2]',
);

const _invoice = InvoiceRecord(
  id: 'invoice-1',
  orderanId: 'order-1',
  invoiceReference: 'INV-2026-088',
  invoiceDate: '2026-09-14',
  dueDate: '2026-09-21',
  productName: 'Sewa Blower Festival Musik Senayan',
  quantity: 4,
  rentalDays: 2,
  unitPrice: 250000,
  subtotal: 2000000,
  totalAmount: 2000000,
  paidAmount: 500000,
  paymentStatus: InvoicePaymentStatus.partial,
  customerName: 'PT Maju Bersama',
  customerPhone: '081234567890',
);

enum _InvoiceFixture { loaded, empty, failure }

class _GoldenGateway extends MaintenanceGateway {
  _GoldenGateway({this.invoiceFixture = _InvoiceFixture.loaded});

  final _InvoiceFixture invoiceFixture;

  @override
  Stream<void> get authChanges => const Stream<void>.empty();

  @override
  Future<UserProfile?> profile() async => _serviceUser;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    return switch (name) {
      'maintenance_get_component' => _componentRow,
      'maintenance_lookup_component' => const <Object?>[_componentRow],
      'maintenance_list_history' => const {
        'items': <Object?>[],
        'nextCursor': null,
      },
      'maintenance_submit' => const {
        'eventId': 'event-1',
        'componentId': 'component-1',
        'version': '2',
      },
      _ => null,
    };
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    bool forceRefresh = false,
  }) async {
    if (kind != null && kind != _componentRow['kind']) return const [];
    return const [_componentRow];
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String periodId = 'current',
    bool forceRefresh = false,
  }) async => const {
    'period': {
      'id': '2026-09',
      'opensAt': '2026-09-26T00:00:00+07:00',
      'closesAt': '2026-09-28T00:00:00+07:00',
      'serverNow': '2026-09-15T08:00:00+07:00',
      'snapshotState': 'ready',
    },
    'total': 1,
    'completed': 0,
    'items': <Object?>[],
  };

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async => const [];

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async => const [_order];

  @override
  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async => _order;

  @override
  Future<List<InvoiceRecord>> fetchInvoices({bool forceRefresh = false}) async {
    return switch (invoiceFixture) {
      _InvoiceFixture.loaded => const [_invoice],
      _InvoiceFixture.empty => const [],
      _InvoiceFixture.failure => throw const AppFailure('unknown'),
    };
  }

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async =>
      _invoice;
}

Widget _app(Widget home) => RepaintBoundary(
  key: _goldenRoot,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: maintenanceTheme(),
    home: home,
  ),
);

Future<void> _capture(WidgetTester tester, String name, Widget home) =>
    withViewport(tester, const Size(390, 844), () async {
      await tester.pumpWidget(_app(home));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(_goldenRoot),
        matchesGoldenFile('goldens/$name.png'),
      );
    });

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
  });

  testWidgets('Login', (tester) async {
    await _capture(
      tester,
      'login',
      LoginScreen(gateway: _GoldenGateway(), onSignedIn: () {}),
    );
  });

  testWidgets('Service Home', (tester) async {
    await _capture(
      tester,
      'service_home',
      HomeScreen(
        gateway: _GoldenGateway(),
        user: _serviceUser,
        onNavigateToTab: (_) {},
        onOpenScanner: () {},
      ),
    );
  });

  testWidgets('PIC Home', (tester) async {
    await _capture(
      tester,
      'pic_home',
      PicHomeScreen(
        gateway: _GoldenGateway(),
        user: _picUser,
        onOpenOrdersTab: () {},
        onOpenInvoicesTab: () {},
        nowProvider: () => DateTime(2026, 9, 15, 12),
      ),
    );
  });

  testWidgets('Catalog', (tester) async {
    await _capture(
      tester,
      'catalog',
      AssetCatalogScreen(
        gateway: _GoldenGateway(),
        onNavigateToTab: (_) {},
        onOpenScanner: () {},
        showBottomNav: false,
      ),
    );
  });

  testWidgets('Component Detail', (tester) async {
    await _capture(
      tester,
      'component_detail',
      ComponentDetailScreen(
        gateway: _GoldenGateway(),
        id: 'component-1',
        user: _serviceUser,
      ),
    );
  });

  testWidgets('Checking', (tester) async {
    await _capture(
      tester,
      'checking',
      CheckingScreen(
        gateway: _GoldenGateway(),
        component: Component(_componentRow),
        taskId: 'task-1',
      ),
    );
  });

  testWidgets('Service Form', (tester) async {
    await _capture(
      tester,
      'service_form',
      CheckingScreen(
        gateway: _GoldenGateway(),
        component: Component(_componentRow),
        service: true,
      ),
    );
  });

  testWidgets('Order List', (tester) async {
    await _capture(
      tester,
      'order_list',
      UpcomingOrdersScreen(gateway: _GoldenGateway(), user: _picUser),
    );
  });

  testWidgets('Order Detail', (tester) async {
    await _capture(
      tester,
      'order_detail',
      OrderDetailScreen(
        order: _order,
        gateway: _GoldenGateway(),
        user: _picUser,
      ),
    );
  });

  testWidgets('Invoice List', (tester) async {
    await _capture(
      tester,
      'invoice_list',
      InvoiceListScreen(gateway: _GoldenGateway(), user: _picUser),
    );
  });

  testWidgets('Invoice Empty', (tester) async {
    await _capture(
      tester,
      'invoice_empty',
      InvoiceListScreen(
        gateway: _GoldenGateway(invoiceFixture: _InvoiceFixture.empty),
        user: _picUser,
      ),
    );
  });

  testWidgets('Invoice Failure', (tester) async {
    await _capture(
      tester,
      'invoice_failure',
      InvoiceListScreen(
        gateway: _GoldenGateway(invoiceFixture: _InvoiceFixture.failure),
        user: _picUser,
      ),
    );
  });

  testWidgets('Component Picker', (tester) async {
    final gateway = _GoldenGateway();
    await withViewport(tester, const Size(390, 844), () async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showComponentPickerSheet(
                    context,
                    gateway: gateway,
                    kind: 'Kepala',
                    usageCounts: const {'KPL-2026-084': 2},
                  ),
                  child: const Text('Pilih komponen'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pilih komponen'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(_goldenRoot),
        matchesGoldenFile('goldens/component_picker.png'),
      );
    });
  });

  testWidgets('Non-camera Scanner Fallback', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _capture(
      tester,
      'scanner_fallback',
      Scaffold(
        body: ScanStatusPanel(
          state: const ScanState(phase: ScanPhase.unavailable),
          manualController: controller,
          onSubmit: (_) {},
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ),
    );
  });
}
