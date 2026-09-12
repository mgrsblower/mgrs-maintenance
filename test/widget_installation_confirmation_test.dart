import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/order_detail_screen.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

class _MockOrderGateway extends MaintenanceGateway {
  _MockOrderGateway({this.order});

  final OrderanSewa? order;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('tech-1', 'Tim Lapangan');

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  @override
  Future<OrderanSewa?> fetchOrderDetail(String id,
      {bool forceRefresh = false}) async {
    return order;
  }
}

Widget orderContextWithoutInstallationContract({UserProfile? user}) {
  final order = OrderanSewa(
    id: 'ord-101',
    namaEvent: 'Konser Musik GBK',
    namaClient: 'Promotor Musik',
    alamat: 'Stadion Utama GBK, Senayan',
    jumlahUnit: 2,
    tanggalPemasangan: DateTime(2026, 9, 20),
  );
  final gateway = _MockOrderGateway(order: order);
  return MaterialApp(
    theme: maintenanceTheme(),
    home: Scaffold(
      body: OrderDetailScreen(
        order: order,
        gateway: gateway,
        user: user ?? const UserProfile('tech-1', 'Tim Lapangan'),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'installation confirmation is unavailable without backend contract',
      (tester) async {
    await tester.pumpWidget(orderContextWithoutInstallationContract());
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi pemasangan belum tersedia'), findsOneWidget);
    expect(find.text('Simpan'), findsNothing);
  });

  testWidgets(
      'Tim Lapangan sees order context without invoice section',
      (tester) async {
    await tester.pumpWidget(
      orderContextWithoutInstallationContract(
        user: const UserProfile('tech-1', 'Tim Lapangan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Konser Musik GBK'), findsOneWidget);
    expect(find.text('Invoice Terkait'), findsNothing);
  });

  testWidgets('PIC sees invoice section in order detail', (tester) async {
    await tester.pumpWidget(
      orderContextWithoutInstallationContract(
        user: const UserProfile('pic-1', 'PIC Pemasangan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invoice Terkait'), findsOneWidget);
  });
}
