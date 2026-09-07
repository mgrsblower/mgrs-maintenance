import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/home/home_skeleton.dart';
import 'package:mgrs_maintenance/features/maintenance/action_center_screen.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';

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
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;
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
    expect(find.text('Besok, 26 Jul 2029'), findsOneWidget);
    expect(find.text('4 Unit'), findsOneWidget);
    expect(find.text('JCC Senayan, Hall B – Jakarta'), findsOneWidget);
    expect(find.text('Dian Wulandari'), findsOneWidget);
    expect(find.text('Hubungi Customer'), findsOneWidget);
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
    expect(find.text('Pemeriksaan Periode Agustus: 142/148 Selesai'), findsOneWidget);
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

    expect(find.text('Update Kondisi'), findsOneWidget);
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
}
