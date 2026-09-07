import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';

class SignedOutGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => null;
  @override
  Future<void> signIn(String identifier, String password) async =>
      throw const AppFailure('invalid_credentials');
  @override
  Future<void> signOut() async {}
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('signed-out users see login and validation, not component data', (
    tester,
  ) async {
    await tester.pumpWidget(MaintenanceApp(gateway: SignedOutGateway()));
    await tester.pumpAndSettle();
    expect(find.text('MGRS Maintenance'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan akun MGRS.'), findsOneWidget);
    expect(find.text('Masukkan kata sandi.'), findsOneWidget);
    expect(find.text('Berkala'), findsNothing);
  });
}
