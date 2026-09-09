import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
import 'package:mgrs_maintenance/features/home/home_skeleton.dart';
import 'package:mgrs_maintenance/features/maintenance/action_center_screen.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';
import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';
import 'package:mgrs_maintenance/features/scan/scan_screen.dart';
import 'package:mgrs_maintenance/features/splash/splash_screen.dart';

class MockGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('u-1', 'Tim Service');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_submit') {
      return {'success': true, 'eventId': 'ev-test-1'};
    }
    if (name == 'maintenance_get_component') {
      return {
        'id': params['p_component_id'] ?? 'c-1',
        'code': 'KPL-2026-084',
        'kind': 'Kepala',
        'condition': 'OK',
        'usable': 'Ya',
        'impairedFunction': 'Tidak Ada',
        'note': 'Kondisi katup & konektor bersih.',
        'version': '1',
      };
    }
    return null;
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({String? periodId}) async {
    return {
      'total': 148,
      'completed': 142,
      'items': [
        {
          'id': 'c-1',
          'code': 'KPL-2026-084',
          'kind': 'Kepala',
          'status': 'completed',
        }
      ],
    };
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
  }) async {
    return [
      {
        'id': 'c-2',
        'nomor_stiker': 'TBG-2026-039',
        'jenis_komponen': 'Tabung',
        'kondisi': 'Service',
      },
      for (int i = 0; i < 4; i++)
        {
          'id': 'c-srv-$i',
          'nomor_stiker': 'TBG-SRV-$i',
          'jenis_komponen': 'Tabung',
          'kondisi': 'Service',
        },
    ];
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({int limit = 10}) async {
    return [
      const OrderanSewa(
        id: 'ord-test-1',
        namaEvent: 'Festival Musik Senayan',
        alamat: 'Parkir Timur Senayan, Jakarta',
        jumlahUnit: 8,
        namaPic: 'Rudi Hartono',
        nomorWhatsapp: '081234567890',
        linkGmaps: 'https://maps.google.com/?q=Senayan',
      ),
      const OrderanSewa(
        id: 'ord-test-2',
        namaEvent: 'Expo Industri Kemayoran',
        alamat: 'JIExpo Kemayoran Hall D',
        jumlahUnit: 5,
        namaPic: 'Siti Rahma',
        nomorWhatsapp: '08987654321',
      ),
    ];
  }
}

void main() {
  testWidgets('OrderDetailScreen renders exact Paper details and contact button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderDetailScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORD-2026-088'), findsOneWidget);
    expect(find.text('Detail Orderan'), findsOneWidget);
    expect(find.text('Jadwal belum ditentukan'), findsOneWidget);
    expect(find.text('4 Unit'), findsOneWidget);
    expect(find.text('PT Pertamina (Persero)'), findsWidgets);
    expect(find.text('Hubungi Pemesan'), findsOneWidget);
  });

  testWidgets('ActionCenterScreen switches between Update Kondisi and Servis', (
    tester,
  ) async {
    final gateway = MockGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: ActionCenterScreen(
          gateway: gateway,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab 1: Update Kondisi
    expect(find.text('Pusat Tindakan'), findsOneWidget);
    expect(find.text('Pemeriksaan Periode Berjalan: 142/148 Selesai'), findsOneWidget);
    expect(find.text('KPL-2026-084'), findsOneWidget);

    // Switch to Tab 2: Servis via icon
    await tester.tap(find.byIcon(Icons.build_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Antrean Unit Bermasalah: 5 Unit Butuh Tindakan'), findsOneWidget);
    expect(find.text('TBG-2026-039'), findsOneWidget);
  });

  testWidgets('CheckingScreen renders Form Update Kondisi (U3-1)', (tester) async {
    final gateway = MockGateway();
    final component = Component({
      'id': 'c-1',
      'code': 'KPL-2026-084',
      'kind': 'Kepala',
      'condition': 'OK',
      'usable': 'Ya',
      'impairedFunction': 'Tidak Ada',
      'note': 'Kondisi katup & konektor bersih.',
      'version': '1',
      'lastCheckingAt': '2026-08-24T00:00:00Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CheckingScreen(
          gateway: gateway,
          component: component,
          service: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui Kondisi'), findsOneWidget);
    expect(find.text('KPL-2026-084'), findsOneWidget);
    expect(find.text('Status Kondisi Hasil Cek *'), findsOneWidget);
    expect(find.text('Layak Pakai'), findsOneWidget);
    expect(find.text('Simpan & Selesaikan Tugas'), findsOneWidget);
  });

  testWidgets('CheckingScreen renders Form Catat Servis (11R-1)', (tester) async {
    final gateway = MockGateway();
    final component = Component({
      'id': 'c-2',
      'code': 'TBG-2026-039',
      'kind': 'Tabung',
      'condition': 'Service',
      'usable': 'Tidak',
      'impairedFunction': 'Bocor katup',
      'note': 'Tekanan turun.',
      'version': '1',
      'lastCheckingAt': '2026-08-24T00:00:00Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CheckingScreen(
          gateway: gateway,
          component: component,
          service: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat Servis'), findsOneWidget);
    expect(find.text('TBG-2026-039'), findsOneWidget);
    expect(find.text('Masalah / Kendala Fisik *'), findsOneWidget);
    expect(find.text('Tindakan Perbaikan yang Dilakukan *'), findsOneWidget);
    expect(find.text('Simpan & Selesaikan Servis'), findsOneWidget);
  });

  testWidgets('HomeSkeletonScreen renders loading placeholders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeSkeletonScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomeSkeletonScreen), findsOneWidget);
  });

  testWidgets('AssetCatalogScreen renders dynamic components from gateway', (
    tester,
  ) async {
    final gateway = DynamicMockGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: AssetCatalogScreen(
          gateway: gateway,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DYNAMIC-KPL-999'), findsOneWidget);
    expect(find.text('DYNAMIC-BTG-888'), findsOneWidget);
  });

  testWidgets('ComponentDetailScreen renders dynamic history from gateway', (
    tester,
  ) async {
    final gateway = DynamicMockGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: ComponentDetailScreen(
          gateway: gateway,
          id: 'c-test-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Pemeriksaan & Servis'), findsOneWidget);
    expect(find.text('Tindakan Servis'), findsOneWidget);
    expect(find.text('Layak Pakai • Teknisi Hendra'), findsOneWidget);
  });

  testWidgets(
      'CheckingScreen submitting Update Kondisi shows success modal and can pop',
      (tester) async {
    final gateway = MockGateway();
    final component = Component({
      'id': 'c-1',
      'code': 'KPL-2026-084',
      'kind': 'Kepala',
      'condition': 'OK',
      'usable': 'Ya',
      'impairedFunction': 'Tidak Ada',
      'note': 'Kondisi katup & konektor bersih.',
      'version': '1',
      'lastCheckingAt': '2026-08-24T00:00:00Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CheckingScreen(
          gateway: gateway,
          component: component,
          service: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitButton = find.text('Simpan & Selesaikan Tugas');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan Berhasil!'), findsOneWidget);
    expect(find.text('Layak Pakai (OK)'), findsOneWidget);
    expect(find.text('Selesai & Kembali'), findsOneWidget);

    await tester.tap(find.text('Selesai & Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan Berhasil!'), findsNothing);
  });

  testWidgets(
      'CheckingScreen submitting Catat Servis shows success modal with action detail',
      (tester) async {
    final gateway = MockGateway();
    final component = Component({
      'id': 'c-2',
      'code': 'TBG-2026-039',
      'kind': 'Tabung',
      'condition': 'Service',
      'usable': 'Tidak',
      'impairedFunction': 'Bocor katup',
      'note': 'Tekanan turun.',
      'version': '1',
      'lastCheckingAt': '2026-08-24T00:00:00Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CheckingScreen(
          gateway: gateway,
          component: component,
          service: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitButton = find.text('Simpan & Selesaikan Servis');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Laporan Servis Berhasil!'), findsOneWidget);
    expect(find.text('Selesai & Kembali'), findsOneWidget);

    await tester.tap(find.text('Selesai & Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Servis Berhasil!'), findsNothing);
  });

  testWidgets('ComponentDetailScreen renders quick action buttons',
      (tester) async {
    final gateway = DynamicMockGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: ComponentDetailScreen(
          gateway: gateway,
          id: 'c-test-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui Kondisi'), findsOneWidget);
    expect(find.text('Catat Servis'), findsOneWidget);
  });

  testWidgets('ScanScreen renders scanner top bar and components',
      (tester) async {
    final gateway = MockGateway();
    final testComp = Component({
      'id': 'c-1',
      'code': 'KPL-2026-084',
      'kind': 'Kepala',
      'condition': 'OK',
      'usable': 'Ya',
      'impairedFunction': 'Tidak Ada',
      'note': 'Kondisi katup & konektor bersih.',
      'version': '1',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ScanScreen(gateway: gateway, initialComponent: testComp),
      ),
    );
    await tester.pump();

    expect(find.text('Scanner Cepat Lapangan'), findsOneWidget);
    expect(find.text('Buka Detail'), findsOneWidget);
    expect(find.text('Pindai Berikutnya'), findsOneWidget);
    expect(find.text('Perbarui Kondisi Unit'), findsOneWidget);
  });

  testWidgets(
      'ScanScreen renders honest idle guide when no component scanned, never creates fake c-1',
      (tester) async {
    final gateway = MockGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: ScanScreen(gateway: gateway),
      ),
    );
    await tester.pump();

    expect(find.text('Scanner Cepat Lapangan'), findsOneWidget);
    expect(find.text('Arahkan Kamera ke Barcode Komponen'), findsOneWidget);
    expect(find.text('Buka Detail'), findsNothing);
    expect(find.text('c-1'), findsNothing);
  });

  testWidgets(
      'AssetCatalogScreen renders empty state when database returns 0 components',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AssetCatalogScreen(
          gateway: EmptyMockGateway(),
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada komponen ditemukan'), findsOneWidget);
    expect(find.text('0 item terdaftar • Kepala, Batang, Tabung'), findsOneWidget);
    // Make sure old default fake codes never appear
    expect(find.text('KPL-2026-001'), findsNothing);
  });

  testWidgets(
      'CheckingScreen does not claim success when server RPC fails',
      (tester) async {
    final gateway = ErrorMockGateway();
    final component = Component({
      'id': 'c-1',
      'code': 'KPL-2026-084',
      'kind': 'Kepala',
      'condition': 'OK',
      'usable': 'Ya',
      'impairedFunction': 'Tidak Ada',
      'note': 'Kondisi katup & konektor bersih.',
      'version': '1',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CheckingScreen(
          gateway: gateway,
          component: component,
          service: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitButton = find.text('Simpan & Selesaikan Tugas');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan Berhasil!'), findsNothing);
    expect(find.text('Konflik Data Pembaruan'), findsOneWidget);
  });

  testWidgets(
      'UpcomingOrdersScreen renders real list of orders and filters by search',
      (tester) async {
    final gateway = MockGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: UpcomingOrdersScreen(gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Orderan Mendatang'), findsOneWidget);
    expect(find.text('Festival Musik Senayan'), findsOneWidget);
    expect(find.text('Expo Industri Kemayoran'), findsOneWidget);
    expect(find.text('8 Unit'), findsOneWidget);
    expect(find.text('5 Unit'), findsOneWidget);

    // Filter by search query
    await tester.enterText(find.byType(TextField), 'Senayan');
    await tester.pumpAndSettle();

    expect(find.text('Festival Musik Senayan'), findsOneWidget);
    expect(find.text('Expo Industri Kemayoran'), findsNothing);
  });

  testWidgets(
      'OrderDetailScreen renders dynamic OrderanSewa with Google Maps and WhatsApp actions',
      (tester) async {
    const order = OrderanSewa(
      id: 'ORD-DYN-999',
      orderanId: 'ORD-20260909-999',
      namaEvent: 'Konser Musik Gelora Bung Karno',
      namaClient: 'PT Promotor Jaya',
      alamat: 'GBK Senayan Pintu 10',
      jumlahUnit: 12,
      namaPic: 'Hendra Setiawan',
      nomorWhatsapp: '081122334455',
      linkGmaps: 'https://maps.google.com/?q=GBK',
      statusOrderan: 'Siap Dipasang',
      catatanOrderan:
          'Harap pasang sebelum jam 10 pagi [SEWA_HARI:3] [TGL_EVENT:2026-09-12]',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OrderDetailScreen(order: order),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORD-20260909-999'), findsOneWidget);
    expect(
        find.text('Nama Event: Konser Musik Gelora Bung Karno'), findsOneWidget);
    expect(find.text('GBK Senayan Pintu 10'), findsOneWidget);
    expect(find.text('12 Unit'), findsOneWidget);
    expect(find.text('3 Hari'), findsOneWidget);
    expect(find.text('Catatan Orderan'), findsOneWidget);
    expect(find.text('Harap pasang sebelum jam 10 pagi'), findsOneWidget);
    expect(find.text('Data Pemesan'), findsOneWidget);
    expect(find.text('PT Promotor Jaya'), findsWidgets);
    expect(find.text('081122334455'), findsOneWidget);
    expect(find.text('Buka di Google Maps'), findsOneWidget);
    expect(find.text('Hubungi Pemesan'), findsOneWidget);
  });

  testWidgets('SplashScreen triggers onFinish callback cleanly', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(onFinish: () => finished = true),
      ),
    );
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });
}

class EmptyMockGateway extends MockGateway {
  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
  }) async {
    return [];
  }
}

class ErrorMockGateway extends MockGateway {
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_submit') {
      throw const AppFailure('conflict');
    }
    return null;
  }
}

class DynamicMockGateway extends MockGateway {
  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
  }) async {
    return [
      {
        'id': 'c-dyn-1',
        'nomor_stiker': 'DYNAMIC-KPL-999',
        'jenis_komponen': 'Kepala',
        'kondisi': 'OK',
        'keterangan': 'Komponen dinamis uji coba database',
        'updated_at': '2026-09-08T05:00:00Z',
      },
      {
        'id': 'c-dyn-2',
        'nomor_stiker': 'DYNAMIC-BTG-888',
        'jenis_komponen': 'Batang',
        'kondisi': 'Service',
        'keterangan': 'Komponen dinamis butuh servis',
        'updated_at': '2026-09-08T05:00:00Z',
      },
    ];
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
  }) async {
    return [
      {
        'eventId': 'ev-1',
        'activity': 'service',
        'recordedAt': '2026-09-08T05:00:00Z',
        'actor': 'Teknisi Hendra',
        'after': {'condition': 'OK'},
      },
    ];
  }

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_get_component') {
      return {
        'id': 'c-test-1',
        'code': 'KPL-TEST-001',
        'kind': 'Kepala',
        'condition': 'OK',
        'usable': 'Ya',
        'impairedFunction': 'Tidak Ada',
        'note': 'Komponen uji coba',
        'version': '1',
      };
    }
    return null;
  }
}
