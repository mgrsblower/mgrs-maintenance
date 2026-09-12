import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';

class _ShellGateway extends MaintenanceGateway {
  _ShellGateway({this.currentProfile});

  UserProfile? currentProfile;
  int signOutCalls = 0;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async => currentProfile;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentProfile = null;
  }

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_list_tasks') {
      return <String, Object?>{
        'period': <String, Object?>{
          'id': '2026-09',
          'opensAt': null,
          'closesAt': null,
          'snapshotState': 'ready',
        },
        'items': <Object?>[],
        'nextCursor': null,
        'total': 0,
        'completed': 0,
      };
    }
    if (name == 'maintenance_list_history') {
      return <String, Object?>{
        'items': <Object?>[],
        'nextCursor': null,
      };
    }
    return null;
  }
}

Widget _testShell({
  required MaintenanceGateway gateway,
  required UserProfile user,
}) {
  return MaterialApp(
    theme: maintenanceTheme(),
    home: MaintenanceHome(gateway: gateway, user: user),
  );
}

int _selectedDestination(WidgetTester tester) {
  final bottomNavigation = find.byType(NavigationBar);
  if (bottomNavigation.evaluate().isNotEmpty) {
    return tester.widget<NavigationBar>(bottomNavigation).selectedIndex;
  }
  return tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;
}

void main() {
  testWidgets('PIC shell exposes only PIC destinations', (tester) async {
    final gateway = _ShellGateway();
    const user = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'PIC MGRS');

    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Orderan'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Berkala'), findsNothing);
    expect(find.text('Komponen'), findsNothing);
    expect(find.text('Riwayat'), findsNothing);
    expect(find.text('Belum ada orderan yang perlu ditindaklanjuti.'), findsOneWidget);
    expect(find.text('Total Orderan\nBulan Ini'), findsNothing);
    expect(find.text('Live Data'), findsNothing);

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();
    final invoiceScreen = tester.widget<InvoiceListScreen>(
      find.byType(InvoiceListScreen),
    );
    expect(identical(invoiceScreen.gateway, gateway), isTrue);
    expect(invoiceScreen.user, same(user));
  });

  testWidgets('field shell exposes only field destinations', (tester) async {
    final gateway = _ShellGateway();
    const user = UserProfile(
      'field-1',
      'Tim Service',
      fullName: 'Petugas Lapangan',
    );

    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Berkala'), findsOneWidget);
    expect(find.text('Komponen'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Orderan'), findsNothing);
    expect(find.text('Invoice'), findsNothing);
    expect(find.text('Pindai komponen'), findsOneWidget);
    expect(find.text('Pengingat!'), findsNothing);
    expect(find.textContaining('mesin aktif dipantau'), findsNothing);

    await tester.tap(find.text('Komponen'));
    await tester.pumpAndSettle();
    final componentsScreen = tester.widget<AssetCatalogScreen>(
      find.byType(AssetCatalogScreen),
    );
    expect(identical(componentsScreen.gateway, gateway), isTrue);
  });

  testWidgets('Admin switcher exposes two workspaces and resets destination', (
    tester,
  ) async {
    final gateway = _ShellGateway();
    const user = UserProfile('admin-1', 'Admin', fullName: 'Administrator');

    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
    await tester.pumpAndSettle();

    expect(find.text('PIC MGRS'), findsOneWidget);
    expect(find.text('Tim Lapangan'), findsOneWidget);
    expect(find.text('Tim Service'), findsNothing);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(_selectedDestination(tester), 3);

    await tester.tap(find.text('PIC MGRS'));
    await tester.pumpAndSettle();
    expect(_selectedDestination(tester), 0);
    expect(find.text('Orderan'), findsOneWidget);
    expect(find.text('Berkala'), findsNothing);

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();
    expect(_selectedDestination(tester), 2);

    await tester.tap(find.text('Tim Lapangan'));
    await tester.pumpAndSettle();
    expect(_selectedDestination(tester), 0);
    expect(find.text('Berkala'), findsOneWidget);
    expect(find.text('Invoice'), findsNothing);
  });

  testWidgets('logout reloads the root session into the login screen', (
    tester,
  ) async {
    const user = UserProfile(
      'field-2',
      'Tim Service',
      fullName: 'Petugas Lapangan',
    );
    final gateway = _ShellGateway(currentProfile: user);

    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keluar dari akun'));
    await tester.pumpAndSettle();

    expect(gateway.signOutCalls, 1);
    expect(find.text('Email / Akun MGRS'), findsOneWidget);
  });
}
