import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/home/home_screen.dart';

class SignedInGateway extends MaintenanceGateway {
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
  testWidgets('HomeScreen renders exact Paper layout components', (tester) async {
    final gateway = SignedInGateway();
    const user = UserProfile('u-1', 'Tim Service');

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
  });
}
