import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/auth/login_screen.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/home/home_screen.dart';
import 'package:mgrs_maintenance/features/home/pic_home_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';

import 'helpers/test_viewport.dart';

const _widths = [320.0, 360.0, 390.0, 430.0];
const _textScales = [1.0, 1.5, 2.0];

const _testUser = UserProfile(
  'admin-1',
  'Admin',
  fullName: 'Super Administrator',
  username: 'admin',
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

const _testOrder = OrderanSewa(
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
  catatanOrderan: 'Pasang sebelum pukul 10.00',
);

class _TestGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => _testUser;
  @override
  Future<void> signIn(String id, String pass) async {}
  @override
  Future<void> signOut() async {}

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async => [_componentRow];

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async => [_testOrder];

  @override
  Future<OrderanSewa?> fetchOrderDetail(String id, {bool forceRefresh = false}) async => _testOrder;

  @override
  Future<List<InvoiceRecord>> fetchInvoices({
    String? orderanId,
    InvoicePaymentStatus? status,
    String? source,
    bool forceRefresh = false,
  }) async => [];

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String id) async => null;

  @override
  Future<Map<String, Object?>> fetchTasksSummary({String? periodId, bool forceRefresh = false}) async => {
    'total': 1,
    'completed': 0,
  };

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(String id, {int limit = 20, bool forceRefresh = false}) async => [];

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_lookup_component' || name == 'maintenance_get_component') {
      return _componentRow;
    }
    return null;
  }
}

Widget _wrap(Widget child) => MaterialApp(
  theme: maintenanceTheme(),
  home: child,
);

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
  });
  group('Responsive width checks (320, 360, 390, 430)', () {
    for (final width in _widths) {
      testWidgets('LoginScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(LoginScreen(gateway: _TestGateway(), onSignedIn: () {})));
          await tester.pumpAndSettle();
          expect(find.text('Masuk ke MGRS'), findsOneWidget);
        });
      });

      testWidgets('HomeScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(HomeScreen(
            gateway: _TestGateway(),
            user: _testUser,
            onNavigateToTab: (_) {},
            onOpenScanner: () {},
          )));
          await tester.pumpAndSettle();
          expect(find.text('Selamat datang'), findsOneWidget);
        });
      });

      testWidgets('PicHomeScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(PicHomeScreen(
            gateway: _TestGateway(),
            user: _testUser,
            onOpenOrdersTab: () {},
            onOpenInvoicesTab: () {},
            nowProvider: () => DateTime(2026, 9, 15, 12),
          )));
          await tester.pumpAndSettle();
          expect(find.text('Total Orderan\nBulan Ini'), findsOneWidget);
        });
      });

      testWidgets('UpcomingOrdersScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(UpcomingOrdersScreen(gateway: _TestGateway(), user: _testUser)));
          await tester.pumpAndSettle();
          expect(find.text('Festival Musik Senayan'), findsOneWidget);
        });
      });

      testWidgets('CheckingScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(CheckingScreen(
            gateway: _TestGateway(),
            component: Component(_componentRow),
          )));
          await tester.pumpAndSettle();
          expect(find.text('Perbarui kondisi'), findsOneWidget);
        });
      });

      testWidgets('InvoiceListScreen renders without overflow at width $width', (tester) async {
        await withViewport(tester, Size(width, 844), () async {
          await tester.pumpWidget(_wrap(InvoiceListScreen(gateway: _TestGateway(), user: _testUser)));
          await tester.pumpAndSettle();
          expect(find.text('Daftar Invoice'), findsOneWidget);
        });
      });
    }
  });

  group('Text scale checks (100%, 150%, 200%)', () {
    for (final scale in _textScales) {
      testWidgets('CheckingScreen usable at textScale $scale', (tester) async {
        await withViewport(tester, const Size(390, 844), () async {
          await tester.pumpWidget(_wrap(CheckingScreen(
            gateway: _TestGateway(),
            component: Component(_componentRow),
          )));
          await tester.pumpAndSettle();
          expect(find.text('Perbarui kondisi'), findsOneWidget);
          expect(find.text('Kondisi komponen'), findsOneWidget);
        }, textScale: scale);
      });

      testWidgets('OrderDetailScreen usable at textScale $scale', (tester) async {
        await withViewport(tester, const Size(390, 844), () async {
          await tester.pumpWidget(_wrap(OrderDetailScreen(
            order: _testOrder,
            gateway: _TestGateway(),
            user: _testUser,
          )));
          await tester.pumpAndSettle();
          expect(find.text('Festival Musik Senayan'), findsOneWidget);
        }, textScale: scale);
      });

      testWidgets('LoginScreen usable at textScale $scale', (tester) async {
        await withViewport(tester, const Size(390, 844), () async {
          await tester.pumpWidget(_wrap(LoginScreen(
            gateway: _TestGateway(),
            onSignedIn: () {},
          )));
          await tester.pumpAndSettle();
          expect(find.text('Masuk ke MGRS'), findsOneWidget);
        }, textScale: scale);
      });
    }
  });

  group('Keyboard visibility and insets on forms', () {
    testWidgets('CheckingScreen adjusts padding for viewInsets.bottom', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(_wrap(CheckingScreen(
        gateway: _TestGateway(),
        component: Component(_componentRow),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Perbarui kondisi'), findsOneWidget);
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listFinder);
      expect((listView.padding as EdgeInsets).bottom, greaterThanOrEqualTo(300));
    });
  });

  group('Draft discard dialog', () {
    testWidgets('CheckingScreen prompts before discarding dirty form', (tester) async {
      await tester.pumpWidget(_wrap(CheckingScreen(
        gateway: _TestGateway(),
        component: Component(_componentRow),
      )));
      await tester.pumpAndSettle();

      // Enter a note to make dirty
      final noteField = find.byType(TextFormField).first;
      await tester.enterText(noteField, 'Catatan kendala pengait');
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      // Discard confirmation dialog shown
      expect(find.text('Batalkan isian?'), findsOneWidget);
      expect(find.text('Tetap di sini'), findsOneWidget);
      expect(find.text('Buang isian'), findsOneWidget);

      // Choose "Tetap di sini"
      await tester.tap(find.text('Tetap di sini'));
      await tester.pumpAndSettle();
      expect(find.text('Perbarui kondisi'), findsOneWidget);
    });
  });

  group('Semantics and TalkBack labels', () {
    testWidgets('Interactive elements have accessible semantic labels', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(HomeScreen(
        gateway: _TestGateway(),
        user: _testUser,
        onNavigateToTab: (_) {},
        onOpenScanner: () {},
      )));
      expect(find.bySemanticsLabel('Profil pengguna, ${_testUser.displayName}'), findsOneWidget);
      expect(find.bySemanticsLabel('Lihat semua'), findsOneWidget);
      expect(find.bySemanticsLabel('Buka pemindai kode'), findsOneWidget);
      semantics.dispose();
    });
  });
}
