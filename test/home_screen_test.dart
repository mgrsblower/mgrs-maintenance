import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/home/home_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

class SignedInGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('u-1', 'Tim Service', fullName: 'Salman Alfarras');
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
  }) async {
    return List.generate(
      24,
      (i) => {
        'id': 'c-$i',
        'nomor_stiker': 'KPL-$i',
        'jenis_komponen': 'Kepala',
        'kondisi': i == 0 ? 'Service' : (i == 1 ? 'Rusak Berat' : 'OK'),
      },
    );
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({String? periodId}) async {
    return {
      'total': 24,
      'completed': 19,
      'period': {
        'opensAt': DateTime.now().add(const Duration(days: 6, hours: 1)).toIso8601String(),
      },
    };
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({int limit = 10}) async {
    return [
      OrderanSewa(
        id: 'ORD-2026-088',
        namaEvent: 'Pemasangan Panggung Event Pertamina',
        alamat: 'JCC Senayan, Hall B - Jakarta',
        jumlahUnit: 4,
        namaPic: 'Dian Wulandari',
        nomorWhatsapp: '081234567890',
        linkGmaps: 'https://maps.google.com/?q=JCC+Senayan',
        tanggalPemasangan: DateTime.now().add(const Duration(days: 1)),
      ),
      OrderanSewa(
        id: 'ORD-2026-092',
        namaEvent: 'Instalasi Outdoor Festival Musik',
        alamat: 'Lapangan Brigif, Cimahi',
        jumlahUnit: 2,
        namaPic: 'Budi Santoso',
        nomorWhatsapp: '089876543210',
        tanggalPemasangan: DateTime.now().add(const Duration(days: 2)),
      ),
    ];
  }
}

void main() {
  testWidgets('HomeScreen renders exact Paper layout components', (tester) async {
    final gateway = SignedInGateway();
    const user = UserProfile('u-1', 'Tim Service', fullName: 'Salman Alfarras');

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          gateway: gateway,
          user: user,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selamat Pagi!'), findsOneWidget);
    expect(find.text('Salman Alfarras'), findsOneWidget);
    expect(find.text('Pengingat!'), findsOneWidget);
    expect(find.text('Pengecekan Unit\nBerkala'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Hari Lagi'), findsOneWidget);
    expect(find.text('Status Unit Blower'), findsOneWidget);
    expect(find.text('Total 24 mesin aktif dipantau'), findsOneWidget);
    expect(find.text('Beroperasi'), findsOneWidget);
    expect(find.text('Perlu Servis'), findsOneWidget);
    expect(find.text('Kendala'), findsOneWidget);
    expect(find.text('Orderan Mendatang'), findsOneWidget);
    expect(find.text('Pemasangan Panggung Event Pertamina'), findsOneWidget);
    expect(find.text('Instalasi Outdoor Festival Musik'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('MaintenanceHome contains Paper bottom bar navigation', (
    tester,
  ) async {
    final gateway = SignedInGateway();
    const user = UserProfile('u-1', 'Tim Service');

    await tester.pumpWidget(
      MaterialApp(
        home: MaintenanceHome(gateway: gateway, user: user),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Aset'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);

    // Tapping 'Aset' animates to page 1
    await tester.tap(find.text('Aset'));
    await tester.pumpAndSettle();
    expect(find.text('Komponen MGRS'), findsOneWidget);

    // Tapping 'Servis' animates to page 2
    await tester.tap(find.text('Servis'));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Tindakan'), findsOneWidget);
  });

  testWidgets('HomeScreen displays dynamic user profile fullName and initials', (
    tester,
  ) async {
    final gateway = SignedInGateway();
    const user = UserProfile(
      'u-2',
      'Tim Service',
      fullName: 'Budi Santoso',
      username: 'budi_s',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          gateway: gateway,
          user: user,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
  });

  testWidgets('HomeScreen renders orders with very long address without horizontal overflow', (
    tester,
  ) async {
    final gateway = SignedInGateway();
    // Simulate narrow mobile screen (360x740)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const user = UserProfile(
      'u-3',
      'Tim Service',
      fullName: 'Muhammad Dzaki Al-Fatih Pratama Kusuma Atmaja',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          gateway: gateway,
          user: user,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no RenderFlex overflow exception occurred
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'Tapping user header opens profile bottom sheet with logout option',
      (tester) async {
    final gateway = SignedInGateway();
    const user = UserProfile(
      'u-4',
      'Tim Service',
      fullName: 'Ahmad Dahlan',
      username: 'ahmad_d',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          gateway: gateway,
          user: user,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap user header
    await tester.tap(find.text('Ahmad Dahlan'));
    await tester.pumpAndSettle();

    // Verify bottom sheet opened
    expect(find.text('Profil Pengguna'), findsOneWidget);
    expect(find.text('Tim Service'), findsWidgets);
    expect(find.text('@ahmad_d'), findsOneWidget);
    expect(find.text('Keluar dari Akun'), findsOneWidget);

    // Tap Keluar dari Akun
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Konfirmasi Keluar'), findsOneWidget);
    expect(find.text('Ya, Keluar'), findsOneWidget);
  });
}

