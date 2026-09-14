import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_app_bar.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_button.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_multiline_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_status_badge.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/maintenance/checking_screen.dart';

enum SubmitOutcome { success, knownFailure, uncertain, conflict, pending }

class CheckingGateway extends MaintenanceGateway {
  CheckingGateway({
    this.submitOutcome = SubmitOutcome.success,
    this.receiptAvailable = false,
    this.reloadFailure,
  });

  SubmitOutcome submitOutcome;
  bool receiptAvailable;
  Object? reloadFailure;
  Map<String, Object?> latestComponent = componentJson(version: '2');
  final submitCompleter = Completer<Object?>();
  final calls = <({String name, Map<String, Object?> params})>[];

  int get submitCalls => calls.where((call) => call.name == 'maintenance_submit').length;
  int get receiptCalls =>
      calls.where((call) => call.name == 'maintenance_request_result').length;
  int get reloadCalls =>
      calls.where((call) => call.name == 'maintenance_get_component').length;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('service-1', 'Tim Service');

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    calls.add((name: name, params: Map<String, Object?>.from(params)));
    if (name == 'maintenance_request_result') {
      return receiptAvailable
          ? {'eventId': 'event-recovered', 'condition': 'OK'}
          : null;
    }
    if (name == 'maintenance_get_component') {
      if (reloadFailure case final failure?) throw failure;
      return latestComponent;
    }
    if (name != 'maintenance_submit') return null;
    return switch (submitOutcome) {
      SubmitOutcome.success => {
          'eventId': 'event-saved',
          'condition': (params['p_command'] as Map)['condition'],
        },
      SubmitOutcome.knownFailure => throw const AppFailure('invalid_input'),
      SubmitOutcome.uncertain => throw Exception('SQL secret'),
      SubmitOutcome.conflict => throw const AppFailure('conflict'),
      SubmitOutcome.pending => await submitCompleter.future,
    };
  }
}

Map<String, Object?> componentJson({String version = '1'}) => {
  'id': 'component-1',
  'code': 'KPL-2026-084',
  'kind': 'Kepala',
  'condition': 'OK',
  'usable': 'Ya',
  'impairedFunction': 'Tidak Ada',
  'note': 'Data awal',
  'version': version,
  'lastCheckingAt': '2026-09-14T10:00:00Z',
};

Component component() => Component(componentJson());

Widget checkingApp(
  CheckingGateway gateway, {
  bool service = false,
  bool routeHarness = false,
}) {
  final screen = CheckingScreen(
    gateway: gateway,
    component: component(),
    service: service,
    taskId: service ? null : 'task-1',
  );
  return MaterialApp(
    theme: maintenanceTheme(),
    home: routeHarness
        ? Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => screen),
                  ),
                  child: const Text('Buka pemeriksaan'),
                ),
              ),
            ),
          )
        : screen,
  );
}

Future<void> pumpChecking(
  WidgetTester tester,
  CheckingGateway gateway, {
  bool service = false,
  bool routeHarness = false,
  double width = 390,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: checkingApp(
        gateway,
        service: service,
        routeHarness: routeHarness,
      ),
    ),
  );
  if (routeHarness) {
    await tester.tap(find.text('Buka pemeriksaan'));
    await tester.pumpAndSettle();
  }
}

Future<void> revealAndTap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(target);
  await tester.pump();
}

Finder fieldWithLabel(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is MgrsMultilineField && widget.label == label,
  ),
  matching: find.byType(TextField),
);

void expectSharedCheckingComponents() {
  expect(find.byType(MgrsDetailAppBar), findsOneWidget);
  expect(find.byType(MgrsStatusBadge), findsWidgets);
  expect(find.byType(MgrsMultilineField), findsWidgets);
  expect(find.byType(MgrsButton), findsWidgets);
}

Future<void> fillServiceFields(WidgetTester tester) async {
  await tester.enterText(
    fieldWithLabel('Masalah / kendala fisik *'),
    'Tekanan turun saat diuji',
  );
  await tester.enterText(
    fieldWithLabel('Tindakan perbaikan *'),
    'Mengganti segel dan menguji ulang',
  );
  await revealAndTap(tester, 'Layak pakai');
}

void main() {
  testWidgets('idle uses shared shell and service required inputs start empty', (
    tester,
  ) async {
    await pumpChecking(tester, CheckingGateway(), service: true);

    expectSharedCheckingComponents();
    expect(find.text('Catat servis'), findsOneWidget);
    expect(find.text('KPL-2026-084'), findsOneWidget);
    expect(
      tester.widget<TextField>(fieldWithLabel('Masalah / kendala fisik *')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextField>(fieldWithLabel('Tindakan perbaikan *')).controller!.text,
      isEmpty,
    );
  });

  testWidgets('invalid service submit shows inline errors and focuses first field', (
    tester,
  ) async {
    await pumpChecking(tester, CheckingGateway(), service: true);
    await revealAndTap(tester, 'Simpan laporan servis');

    expect(find.text('Periksa kembali isian'), findsOneWidget);
    expect(find.text('Jelaskan masalah yang ditemukan.'), findsOneWidget);
    expect(
      find.text('Tuliskan tindakan servis yang dilakukan.'),
      findsOneWidget,
    );
    expect(find.text('Kondisi setelah servis belum dipilih'), findsOneWidget);
    expect(
      find.text('Pilih Layak pakai atau Perlu servis lanjutan.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(fieldWithLabel('Masalah / kendala fisik *')).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets('pending submit disables actions and exposes loading state', (
    tester,
  ) async {
    final gateway = CheckingGateway(submitOutcome: SubmitOutcome.pending);
    await pumpChecking(tester, gateway);
    await revealAndTap(tester, 'Simpan pemeriksaan');

    expect(gateway.submitCalls, 1);
    final button = tester.widget<MgrsButton>(find.byType(MgrsButton).last);
    expect(button.loading, isTrue);
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gateway.submitCompleter.complete({'eventId': 'event-saved'});
    await tester.pumpAndSettle();
  });

  testWidgets('known failure shows safe copy and never leaks backend details', (
    tester,
  ) async {
    final gateway = CheckingGateway(submitOutcome: SubmitOutcome.knownFailure);
    await pumpChecking(tester, gateway);
    await revealAndTap(tester, 'Simpan pemeriksaan');
    await tester.pumpAndSettle();

    expect(find.text('Data belum dapat disimpan'), findsOneWidget);
    expect(
      find.text('Periksa kembali isian, lalu coba simpan lagi.'),
      findsOneWidget,
    );
    expect(find.textContaining('SQL secret'), findsNothing);
    expect(find.textContaining('invalid_input'), findsNothing);
  });

  testWidgets('uncertain action checks receipt and does not mutate twice', (
    tester,
  ) async {
    final gateway = CheckingGateway(
      submitOutcome: SubmitOutcome.uncertain,
      receiptAvailable: true,
    );
    await pumpChecking(tester, gateway);
    await revealAndTap(tester, 'Simpan pemeriksaan');
    await tester.pumpAndSettle();

    expect(find.textContaining('SQL secret'), findsNothing);
    await revealAndTap(tester, 'Periksa status penyimpanan');
    await tester.pumpAndSettle();

    expect(gateway.receiptCalls, 1);
    expect(gateway.submitCalls, 1);
    expect(find.text('Pemeriksaan tersimpan'), findsOneWidget);
  });

  testWidgets('conflict keeps draft through failed reload then clears on success', (
    tester,
  ) async {
    final gateway = CheckingGateway(
      submitOutcome: SubmitOutcome.conflict,
      reloadFailure: Exception('SQL secret'),
    );
    await pumpChecking(tester, gateway);
    final note = fieldWithLabel('Catatan pemeriksaan · opsional');
    await tester.enterText(note, 'Draft penting petugas');
    await revealAndTap(tester, 'Rusak berat');
    await tester.enterText(
      fieldWithLabel('Fungsi yang terganggu *'),
      'Tekanan tidak stabil',
    );
    await revealAndTap(tester, 'Simpan pemeriksaan');
    await tester.pumpAndSettle();

    expect(find.text('Data telah diperbarui petugas lain'), findsOneWidget);
    expect(
      find.text(
        'Muat kondisi terbaru sebelum menyimpan kembali. Draft catatan Anda tetap aman.',
      ),
      findsOneWidget,
    );
    await revealAndTap(tester, 'Muat data terbaru');
    await tester.pumpAndSettle();
    expect(gateway.reloadCalls, 1);
    expect(find.text('Draft penting petugas'), findsOneWidget);
    expect(find.textContaining('SQL secret'), findsNothing);

    gateway.reloadFailure = null;
    await revealAndTap(tester, 'Muat data terbaru');
    await tester.pumpAndSettle();
    expect(gateway.reloadCalls, 2);
    expect(find.text('Draft penting petugas'), findsOneWidget);
    expect(find.text('Rusak berat'), findsOneWidget);
  });

  testWidgets('service follow-up requires and submits condition details', (
    tester,
  ) async {
    final gateway = CheckingGateway();
    await pumpChecking(tester, gateway, service: true);
    await tester.enterText(
      fieldWithLabel('Masalah / kendala fisik *'),
      'Tekanan turun saat diuji',
    );
    await tester.enterText(
      fieldWithLabel('Tindakan perbaikan *'),
      'Mengganti segel dan menguji ulang',
    );
    await revealAndTap(tester, 'Perlu servis lanjutan');
    await revealAndTap(tester, 'Simpan laporan servis');

    expect(find.text('Jelaskan kondisi setelah servis.'), findsOneWidget);
    expect(find.text('Jelaskan fungsi yang masih terganggu.'), findsOneWidget);
    expect(gateway.submitCalls, 0);

    await tester.enterText(
      fieldWithLabel('Catatan kondisi setelah servis *'),
      'Masih perlu penggantian katup',
    );
    await tester.enterText(
      fieldWithLabel('Fungsi yang masih terganggu *'),
      'Tekanan belum stabil',
    );
    await revealAndTap(tester, 'Simpan laporan servis');
    await tester.pumpAndSettle();

    final command = gateway.calls
        .singleWhere((call) => call.name == 'maintenance_submit')
        .params['p_command'] as Map;
    expect(command['condition'], 'Service');
    expect(command['usable'], 'Tidak');
    expect(command['eventNote'], 'Masih perlu penggantian katup');
    expect(command['impairedFunction'], 'Tekanan belum stabil');
    expect(find.text('Laporan servis tersimpan'), findsOneWidget);
  });

  for (final service in [false, true]) {
    testWidgets(
      '${service ? 'service' : 'checking'} success uses backend-confirmed shared sheet',
      (tester) async {
        final gateway = CheckingGateway();
        await pumpChecking(tester, gateway, service: service);
        if (service) await fillServiceFields(tester);
        await revealAndTap(
          tester,
          service ? 'Simpan laporan servis' : 'Simpan pemeriksaan',
        );
        await tester.pumpAndSettle();

        expect(gateway.submitCalls, 1);
        expect(
          find.text(service ? 'Laporan servis tersimpan' : 'Pemeriksaan tersimpan'),
          findsOneWidget,
        );
        expect(
          find.text(
            service
                ? 'Catatan perbaikan dan kondisi terbaru komponen sudah diperbarui.'
                : 'Hasil pemeriksaan rutin sudah disimpan ke sistem MGRS.',
          ),
          findsOneWidget,
        );
        expect(find.text('Selesai'), findsOneWidget);
      },
    );
  }

  testWidgets('choice-only edit requires discard confirmation on back', (
    tester,
  ) async {
    await pumpChecking(
      tester,
      CheckingGateway(),
      routeHarness: true,
    );
    await revealAndTap(tester, 'Rusak berat');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Batalkan isian?'), findsOneWidget);
    expect(find.text('Tetap di sini'), findsOneWidget);
    expect(find.text('Buang isian'), findsOneWidget);
    await tester.tap(find.text('Tetap di sini'));
    await tester.pumpAndSettle();
    expect(find.text('Perbarui kondisi'), findsOneWidget);
  });

  testWidgets('320 px at 200% text keeps key actions reachable by scrolling', (
    tester,
  ) async {
    await pumpChecking(
      tester,
      CheckingGateway(),
      service: true,
      width: 320,
      textScale: 2,
    );

    expectSharedCheckingComponents();
    await tester.scrollUntilVisible(
      find.text('Simpan laporan servis'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Simpan laporan servis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
