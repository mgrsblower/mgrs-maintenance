import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';

class _FailingFieldGateway extends MaintenanceGateway {
  final List<String> submittedCommands = [];

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async => null;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_submit') {
      submittedCommands.add(name);
      throw const AppFailure('invalid_input');
    }
    return null;
  }
}

class _SuccessFieldGateway extends MaintenanceGateway {
  final List<Map<String, Object?>> submittedCommands = [];

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async => null;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_submit') {
      final cmd = params['p_command'] as Map<String, Object?>?;
      if (cmd != null) submittedCommands.add(cmd);
      return {'status': 'ok'};
    }
    return null;
  }
}

final _testComponent = Component({
  'id': 'c-101',
  'code': 'KPL-001',
  'kind': 'Kepala',
  'condition': 'OK',
  'usable': 'Ya',
  'impairedFunction': 'Tidak Ada',
  'version': '1',
});

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: maintenanceTheme(),
    home: child,
  );
}

void main() {
  testWidgets('checking form starts without condition or usability',
      (tester) async {
    final gateway = _SuccessFieldGateway();
    await tester.pumpWidget(
      _wrap(
        CheckingScreen(
          gateway: gateway,
          component: _testComponent,
          service: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('condition-empty')), findsOneWidget);
    expect(find.text('OK'), findsNothing);
    expect(find.text('Ya'), findsNothing);
  });

  testWidgets('service form starts empty and preserves input after failure',
      (tester) async {
    final gateway = _FailingFieldGateway();
    await tester.pumpWidget(
      _wrap(
        CheckingScreen(
          gateway: gateway,
          component: _testComponent,
          service: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('problem-field')), 'Pompa macet');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Pompa macet'), findsOneWidget);
    expect(find.text('Gagal menyimpan'), findsOneWidget);
  });

  testWidgets('dirty state warns before leaving form', (tester) async {
    final gateway = _SuccessFieldGateway();
    await tester.pumpWidget(
      _wrap(
        CheckingScreen(
          gateway: gateway,
          component: _testComponent,
          service: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('problem-field')), 'Baut kendur');
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Batalkan isian?'), findsOneWidget);
    expect(find.text('Buang isian'), findsOneWidget);

    await tester.tap(find.text('Tetap di sini'));
    await tester.pumpAndSettle();

    expect(find.text('Baut kendur'), findsOneWidget);
  });

  testWidgets('selecting condition and submitting records maintenance command',
      (tester) async {
    final gateway = _SuccessFieldGateway();
    await tester.pumpWidget(
      _wrap(
        CheckingScreen(
          gateway: gateway,
          component: _testComponent,
          service: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Layak Pakai'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('condition-empty')), findsNothing);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(gateway.submittedCommands.length, 1);
    final cmd = gateway.submittedCommands.first;
    expect(cmd['condition'], 'OK');
    expect(cmd['usable'], 'Ya');
    expect(cmd['activity'], 'manual_check');
  });
}
