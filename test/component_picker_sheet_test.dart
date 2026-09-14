import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_search_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_state_view.dart';
import 'package:mgrs_maintenance/features/schedule/component_picker_sheet.dart';

typedef ComponentResponse = Future<List<Map<String, Object?>>> Function();

class PickerGateway extends MaintenanceGateway {
  PickerGateway(this.responses);

  final List<ComponentResponse> responses;
  int fetchCount = 0;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('u-1', 'Tim Pemasangan');

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
    bool forceRefresh = false,
  }) {
    final responseIndex = fetchCount < responses.length
        ? fetchCount
        : responses.length - 1;
    fetchCount++;
    return responses[responseIndex]();
  }
}

const usableComponents = <Map<String, Object?>>[
  {
    'nomor_stiker': 'K-01',
    'jenis_komponen': 'Kepala',
    'kondisi': 'OK',
    'boleh_dipakai': 'Ya',
    'lokasi': 'Gudang Utama',
  },
  {
    'nomor_stiker': 'K-02',
    'jenis_komponen': 'Kepala',
    'kondisi': 'Service',
    'boleh_dipakai': 'Ya',
    'lokasi': 'Rak Timur',
  },
];

void main() {
  testWidgets('keeps the picker shell visible while loading', (tester) async {
    final pending = Completer<List<Map<String, Object?>>>();
    final gateway = PickerGateway([() => pending.future]);

    await openPicker(tester, gateway);

    expectPickerShell();
    expect(find.byType(MgrsStateView), findsOneWidget);
    expect(find.text('Memuat komponen Kepala...'), findsOneWidget);
  });

  testWidgets('keeps the picker shell visible for an empty inventory', (
    tester,
  ) async {
    final gateway = PickerGateway([() async => []]);

    await openPicker(tester, gateway, settle: true);

    expectPickerShell();
    expect(find.byType(MgrsStateView), findsOneWidget);
    expect(find.text('Belum ada Kepala siap pakai'), findsOneWidget);
  });

  testWidgets('sanitizes failures and retries component loading', (
    tester,
  ) async {
    const rawError =
        'PostgrestException: relation secret_components SQLSTATE 42P01';
    final gateway = PickerGateway([
      () => Future.error(Exception(rawError)),
      () async => usableComponents,
    ]);

    await openPicker(tester, gateway, settle: true);

    expectPickerShell();
    expect(find.byType(MgrsStateView), findsOneWidget);
    expect(find.text('Komponen gagal dimuat'), findsOneWidget);
    expect(find.textContaining(rawError), findsNothing);
    expect(gateway.fetchCount, 1);

    await tester.tap(find.text('Muat data terbaru'));
    await tester.pumpAndSettle();

    expect(gateway.fetchCount, 2);
    expect(find.text('K-02'), findsOneWidget);
  });

  testWidgets('sorts least-used components and filters unavailable items', (
    tester,
  ) async {
    final gateway = PickerGateway([
      () async => [
        ...usableComponents,
        {
          'nomor_stiker': 'K-03',
          'jenis_komponen': 'Kepala',
          'kondisi': 'Rusak Berat',
          'boleh_dipakai': 'Ya',
        },
        {
          'nomor_stiker': 'K-04',
          'jenis_komponen': 'Kepala',
          'kondisi': 'OK',
          'boleh_dipakai': 'Tidak',
        },
      ],
    ]);

    await openPicker(
      tester,
      gateway,
      usageCounts: const {'K-01': 10, 'K-02': 2},
      settle: true,
    );

    expectPickerShell();
    expect(find.text('K-03'), findsNothing);
    expect(find.text('K-04'), findsNothing);
    expect(
      tester.getTopLeft(find.text('K-02')).dy,
      lessThan(tester.getTopLeft(find.text('K-01')).dy),
    );
  });

  testWidgets(
    'searches component metadata and preserves shell for no results',
    (tester) async {
      final gateway = PickerGateway([() async => usableComponents]);

      await openPicker(tester, gateway, settle: true);
      await tester.enterText(find.byType(TextField), 'Rak Timur');
      await tester.pump();

      expect(find.text('K-02'), findsOneWidget);
      expect(find.text('K-01'), findsNothing);

      await tester.enterText(find.byType(TextField), 'tidak-ada');
      await tester.pump();

      expectPickerShell();
      expect(find.byType(MgrsStateView), findsOneWidget);
      expect(find.text('Pencarian tidak ditemukan'), findsOneWidget);
      expect(find.textContaining('Tidak ada data yang cocok'), findsOneWidget);
    },
  );

  testWidgets('marks current selection and can clear it with an empty result', (
    tester,
  ) async {
    final gateway = PickerGateway([() async => usableComponents]);
    String? result;

    await openPicker(
      tester,
      gateway,
      currentSticker: 'K-02',
      onResult: (value) => result = value,
      settle: true,
    );

    expect(find.text('Terpilih'), findsOneWidget);
    await tester.tap(find.text('Kosongkan pilihan'));
    await tester.pumpAndSettle();

    expect(result, '');
  });

  testWidgets('has no overflow at 320 px and 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    final gateway = PickerGateway([() async => usableComponents]);

    await openPicker(
      tester,
      gateway,
      currentSticker: 'K-02',
      textScale: 2,
      settle: true,
    );

    expectPickerShell();
    expect(tester.takeException(), isNull);
  });
}

Future<void> openPicker(
  WidgetTester tester,
  MaintenanceGateway gateway, {
  Map<String, int> usageCounts = const {'K-01': 10, 'K-02': 2},
  String? currentSticker,
  ValueChanged<String?>? onResult,
  double textScale = 1,
  bool settle = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showComponentPickerSheet(
                  context,
                  gateway: gateway,
                  kind: 'Kepala',
                  usageCounts: usageCounts,
                  currentSticker: currentSticker,
                );
                onResult?.call(result);
              },
              child: const Text('Buka pemilih'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka pemilih'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void expectPickerShell() {
  expect(find.text('Pilih Kepala Blower'), findsOneWidget);
  expect(find.byType(MgrsSearchField), findsOneWidget);
  expect(find.byTooltip('Tutup pemilih komponen'), findsOneWidget);
}
