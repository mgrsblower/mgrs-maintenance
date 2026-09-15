import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/scan/scan_screen.dart';
import 'package:mgrs_maintenance/features/scan/scan_state.dart';

class _ScanGateway extends MaintenanceGateway {
  _ScanGateway(this.outcomes);

  final List<Object?> outcomes;
  final List<String> codes = [];
  var calls = 0;

  @override
  Stream<void> get authChanges => const Stream<void>.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('tech', 'Tim Service');

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name != 'maintenance_lookup_component') return null;
    codes.add(params['p_code']! as String);
    final index = calls < outcomes.length ? calls : outcomes.length - 1;
    calls += 1;
    final outcome = outcomes[index];
    if (outcome is Future<Object?>) return outcome;
    if (outcome is Exception) throw outcome;
    return outcome;
  }
}

const _componentRow = <String, Object?>{
  'id': 'c-1',
  'code': 'KPL-001',
  'kind': 'Kepala',
  'condition': 'OK',
  'usable': 'Ya',
  'impairedFunction': 'Tidak Ada',
  'version': '1',
};

Future<void> _pump(WidgetTester tester, _ScanGateway gateway) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: ScanScreen(gateway: gateway)));
  await tester.pump();
}

Finder _manualField() => find.byKey(const Key('scan-manual-code-field'));
Finder _submit() => find.byKey(const Key('scan-manual-submit'));

void main() {
  testWidgets('keeps scanner shell and manual entry during lookup', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    final gateway = _ScanGateway([pending.future]);
    await _pump(tester, gateway);

    expect(find.text('Scanner Cepat Lapangan'), findsOneWidget);
    expect(_manualField(), findsOneWidget);
    await tester.enterText(_manualField(), ' KPL-001 ');
    await tester.tap(_submit());
    await tester.pump();

    expect(find.byKey(const Key('scan-phase-lookingUp')), findsOneWidget);
    expect(_manualField(), findsOneWidget);
    await tester.tap(_submit());
    expect(gateway.calls, 1);

    pending.complete([_componentRow]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-phase-result')), findsOneWidget);
    expect(find.text('KPL-001'), findsOneWidget);
  });

  testWidgets('not-found offers retry and keeps manual search available', (
    tester,
  ) async {
    final gateway = _ScanGateway([
      const <Object?>[],
      [_componentRow],
    ]);
    await _pump(tester, gateway);
    await tester.enterText(_manualField(), 'UNKNOWN');
    await tester.tap(_submit());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scan-phase-notFound')), findsOneWidget);
    expect(find.text('Komponen tidak ditemukan'), findsOneWidget);
    expect(_manualField(), findsOneWidget);
    expect(find.text('Coba kode ini lagi'), findsOneWidget);

    await tester.tap(find.text('Coba kode ini lagi'));
    await tester.pumpAndSettle();
    expect(gateway.codes, ['UNKNOWN', 'UNKNOWN']);
    expect(find.byKey(const Key('scan-phase-result')), findsOneWidget);
  });

  testWidgets('ambiguous result explains conflict and blocks selection', (
    tester,
  ) async {
    final gateway = _ScanGateway([
      const <Object?>[_componentRow, _componentRow],
    ]);
    await _pump(tester, gateway);
    await tester.enterText(_manualField(), 'DUPLICATE');
    await tester.tap(_submit());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scan-phase-ambiguous')), findsOneWidget);
    expect(find.textContaining('tidak unik'), findsOneWidget);
    expect(find.text('Buka Detail'), findsNothing);
    expect(_manualField(), findsOneWidget);
  });

  testWidgets('network failure is sanitized and supports another code', (
    tester,
  ) async {
    final gateway = _ScanGateway([
      Exception('Socket SQLSTATE secret implementation detail'),
    ]);
    await _pump(tester, gateway);
    await tester.enterText(_manualField(), 'KPL-009');
    await tester.tap(_submit());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scan-phase-networkFailure')), findsOneWidget);
    expect(find.textContaining('Koneksi'), findsOneWidget);
    expect(find.textContaining('SQLSTATE'), findsNothing);
    expect(_manualField(), findsOneWidget);
  });

  testWidgets('status panel covers camera permission and unavailable states', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanStatusPanel(
            state: const ScanState(phase: ScanPhase.permissionDenied),
            manualController: controller,
            onSubmit: (_) {},
            onRetry: () {},
            onOpenSettings: () {},
          ),
        ),
      ),
    );
    expect(find.text('Izin kamera diperlukan'), findsOneWidget);
    expect(find.text('Buka pengaturan'), findsOneWidget);
    expect(_manualField(), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanStatusPanel(
            state: const ScanState(phase: ScanPhase.unavailable),
            manualController: controller,
            onSubmit: (_) {},
            onRetry: () {},
            onOpenSettings: () {},
          ),
        ),
      ),
    );
    expect(find.text('Kamera tidak tersedia'), findsOneWidget);
    expect(_manualField(), findsOneWidget);
  });

  testWidgets('manual fallback fits 320 px at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ScanStatusPanel(
                state: const ScanState(phase: ScanPhase.networkFailure),
                manualController: controller,
                onSubmit: (_) {},
                onRetry: () {},
                onOpenSettings: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(_manualField(), findsOneWidget);
  });

  testWidgets('camera lifecycle pause and resume stay safe', (tester) async {
    await _pump(tester, _ScanGateway([const <Object?>[]]));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Scanner Cepat Lapangan'), findsOneWidget);
  });

  testWidgets('late lookup completion is ignored after scanner disposal', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    final gateway = _ScanGateway([pending.future]);
    await _pump(tester, gateway);
    await tester.enterText(_manualField(), 'KPL-001');
    await tester.tap(_submit());
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete([_componentRow]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
