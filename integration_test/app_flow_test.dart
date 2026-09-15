import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

class SyntheticGateway extends MaintenanceGateway {
  SyntheticGateway({
    this.initialSignedIn = false,
  }) : _signedIn = initialSignedIn;

  final bool initialSignedIn;
  bool _signedIn;
  bool _sessionExpired = false;
  bool invoiceFailure = false;

  final _authStreamController = StreamController<void>.broadcast();

  final adminUser = const UserProfile(
    'admin-1',
    'Admin',
    fullName: 'Super Administrator',
    username: 'admin',
  );

  static const _componentRow = <String, Object?>{
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

  static final _order = OrderanSewa(
    id: 'order-1',
    orderanId: 'ORD-2026-088',
    namaEvent: 'Festival Musik Senayan',
    namaClient: 'PT Maju Bersama',
    alamat: 'Parkir Timur Senayan, Jakarta',
    jumlahUnit: 4,
    namaPic: 'Rudi Hartono',
    nomorWhatsapp: '081234567890',
    linkGmaps: 'https://maps.google.com/?q=Senayan',
    tanggalPemasangan: DateTime(2026, 9, 20),
    statusOrderan: 'Terjadwal',
    catatanOrderan: 'Pasang sebelum pukul 10.00',
  );

  @override
  Stream<void> get authChanges => _authStreamController.stream;

  @override
  Future<UserProfile?> profile() async {
    if (_sessionExpired) {
      throw const AppFailure('unauthenticated');
    }
    if (!_signedIn) {
      return null;
    }
    return adminUser;
  }

  @override
  Future<void> signIn(String identifier, String password) async {
    _signedIn = true;
    _sessionExpired = false;
    _authStreamController.add(null);
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _authStreamController.add(null);
  }

  void triggerSessionExpiry() {
    _sessionExpired = true;
    _authStreamController.add(null);
  }

  void dispose() {
    _authStreamController.close();
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async {
    return [_componentRow];
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    return [_order];
  }

  @override
  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async {
    return _order;
  }

  @override
  Future<List<InvoiceRecord>> fetchInvoices({
    String? orderanId,
    InvoicePaymentStatus? status,
    String? source,
    bool forceRefresh = false,
  }) async {
    if (invoiceFailure) {
      throw const AppFailure('unknown');
    }
    return [];
  }

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async => null;

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String? periodId,
    bool forceRefresh = false,
  }) async {
    return {
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
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    return [];
  }

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    switch (name) {
      case 'maintenance_lookup_component':
        return [_componentRow];
      case 'maintenance_get_component':
        return _componentRow;
      case 'maintenance_submit':
        final cmd = params['p_command'] as Map?;
        return {
          'eventId': 'event-1',
          'requestId': cmd?['requestId'] ?? 'req-1',
          'componentId': 'component-1',
          'version': '2',
          'recordedAt': DateTime.now().toIso8601String(),
        };
      case 'maintenance_list_tasks':
        return {
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
          'nextCursor': null,
        };
      case 'maintenance_list_history':
        return {'items': <Object?>[], 'nextCursor': null};
      case 'maintenance_request_result':
        return null;
      default:
        return null;
    }
  }
}

Future<void> _safeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.takeScreenshot(name);
  } catch (_) {
    // Non-fatal if driver/binding does not support screenshots in current host
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Flow 1: login -> Service shell -> Aset -> detail komponen -> form checking -> submit -> success',
    (tester) async {
      final gateway = SyntheticGateway(initialSignedIn: false);
      addTearDown(gateway.dispose);

      await tester.pumpWidget(MaintenanceApp(gateway: gateway));
      await tester.pumpAndSettle();

      // 1. Verify Login screen
      expect(find.text('Masuk ke MGRS'), findsOneWidget);

      // 2. Enter credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // 3. Submit login
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();

      // 4. Verify Service shell
      expect(find.text('Selamat datang'), findsOneWidget);
      expect(find.text('Aset'), findsOneWidget);
      await _safeScreenshot(binding, 'flow1_service_shell');

      // 5. Navigate to Tab 1 (Aset)
      await tester.tap(find.byKey(const ValueKey('nav-item-1')));
      await tester.pumpAndSettle();

      // 6. Verify Asset Catalog and select component
      expect(find.text('KPL-2026-084'), findsOneWidget);
      await tester.tap(find.text('KPL-2026-084'));
      await tester.pumpAndSettle();

      // 7. Verify Component Detail and tap Perbarui Kondisi
      expect(find.text('Perbarui Kondisi'), findsOneWidget);
      await tester.tap(find.text('Perbarui Kondisi'));
      await tester.pumpAndSettle();

      // 8. In CheckingScreen, tap Simpan pemeriksaan
      expect(find.text('Perbarui kondisi'), findsOneWidget);
      final saveButton = find.widgetWithText(FilledButton, 'Simpan pemeriksaan');
      expect(saveButton, findsOneWidget);
      await tester.scrollUntilVisible(
        saveButton,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 9. Verify Success Sheet and tap Selesai
      expect(find.text('Pemeriksaan tersimpan'), findsOneWidget);
      await _safeScreenshot(binding, 'flow1_checking_success');
      final doneButton = find.widgetWithText(FilledButton, 'Selesai');
      expect(doneButton, findsOneWidget);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      // 10. Verify back on Component Detail screen
      expect(find.text('KPL-2026-084'), findsOneWidget);
    },
  );

  testWidgets(
    'Flow 2: Admin -> buka profil -> Mode PIC -> Orderan -> detail order -> kembali -> Invoice',
    (tester) async {
      final gateway = SyntheticGateway(initialSignedIn: true);
      addTearDown(gateway.dispose);

      await tester.pumpWidget(MaintenanceApp(gateway: gateway));
      await tester.pumpAndSettle();

      // 1. In Service Home, tap user profile avatar
      final avatar = find.text('SA');
      expect(avatar, findsOneWidget);
      await tester.tap(avatar);
      await tester.pumpAndSettle();

      // 2. In Profile Sheet, tap Mode PIC
      expect(find.text('Mode tampilan'), findsOneWidget);
      expect(find.text('Mode PIC'), findsOneWidget);
      await tester.tap(find.text('Mode PIC'));
      await tester.pumpAndSettle();

      // 3. Verify PIC Mode active and tap Tab 1 (Orderan)
      expect(find.text('Orderan'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('nav-item-1')));
      await tester.pumpAndSettle();

      // 4. In UpcomingOrdersScreen, tap order card
      expect(find.text('Festival Musik Senayan'), findsOneWidget);
      await _safeScreenshot(binding, 'flow2_order_list');
      await tester.tap(find.text('Festival Musik Senayan'));
      await tester.pumpAndSettle();

      // 5. In OrderDetailScreen, verify order reference
      expect(find.text('ORD-2026-088'), findsOneWidget);
      await _safeScreenshot(binding, 'flow2_order_detail');

      // 6. Navigate back
      final backButton = find.byTooltip('Kembali');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
      } else {
        final backIcon = find.byIcon(Icons.arrow_back);
        if (backIcon.evaluate().isNotEmpty) {
          await tester.tap(backIcon.first);
        } else {
          await tester.pageBack();
        }
      }
      await tester.pumpAndSettle();

      // 7. Back on UpcomingOrdersScreen, tap Tab 2 (Invoice)
      expect(find.text('Festival Musik Senayan'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-item-2')));
      await tester.pumpAndSettle();

      // 8. Verify Invoice screen is displayed
      expect(find.text('Daftar Invoice'), findsOneWidget);
      await _safeScreenshot(binding, 'flow2_invoice_list');
    },
  );

  testWidgets(
    'Flow 3: Invoice error -> retry -> empty, dengan shell/nav tetap bisa dipakai',
    (tester) async {
      final gateway = SyntheticGateway(initialSignedIn: true);
      gateway.invoiceFailure = true;
      addTearDown(gateway.dispose);

      await tester.pumpWidget(MaintenanceApp(gateway: gateway));
      await tester.pumpAndSettle();

      // Switch to PIC mode first
      final avatar = find.text('SA');
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mode PIC'));
      await tester.pumpAndSettle();

      // Navigate to Tab 2 (Invoice)
      await tester.tap(find.byKey(const ValueKey('nav-item-2')));
      await tester.pumpAndSettle();

      // 1. Verify error state
      expect(find.text('Invoice gagal dimuat'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bottom-navigation-content')),
        findsOneWidget,
      );
      await _safeScreenshot(binding, 'flow3_invoice_error');

      // 2. Fix error condition in gateway
      gateway.invoiceFailure = false;

      // 3. Tap retry button
      final retryButton = find.text('Muat data terbaru');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // 4. Verify empty state displayed
      expect(find.text('Belum ada invoice'), findsOneWidget);
      // Navigation bar remains visible and responsive
      expect(
        find.byKey(const ValueKey('bottom-navigation-content')),
        findsOneWidget,
      );
      await _safeScreenshot(binding, 'flow3_invoice_empty');
    },
  );

  testWidgets(
    'Flow 4: session expiry/AppFailure("unauthenticated") -> Sesi Anda telah berakhir -> Masuk kembali -> Login',
    (tester) async {
      final gateway = SyntheticGateway(initialSignedIn: true);
      addTearDown(gateway.dispose);

      await tester.pumpWidget(MaintenanceApp(gateway: gateway));
      await tester.pumpAndSettle();

      // 1. Initially authenticated in Service shell
      expect(find.text('Selamat datang'), findsOneWidget);

      // 2. Trigger session expiry
      gateway.triggerSessionExpiry();
      await tester.pump();
      await tester.pumpAndSettle();

      // 3. Verify session expired banner/screen
      expect(find.text('Sesi Anda telah berakhir'), findsOneWidget);
      expect(
        find.text('Masuk kembali untuk melanjutkan pekerjaan Anda.'),
        findsOneWidget,
      );
      await _safeScreenshot(binding, 'flow4_session_expired');

      // 4. Tap "Masuk kembali"
      final returnButton = find.widgetWithText(FilledButton, 'Masuk kembali');
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      // 5. Verify returned to LoginScreen
      expect(find.text('Masuk ke MGRS'), findsOneWidget);
      await _safeScreenshot(binding, 'flow4_login_screen');
    },
  );
}
