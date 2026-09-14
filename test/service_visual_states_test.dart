import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
import 'package:mgrs_maintenance/features/history/history_screen.dart';
import 'package:mgrs_maintenance/features/maintenance/action_center_screen.dart';

class ServiceStateGateway extends MaintenanceGateway {
  ServiceStateGateway({
    this.components = const [],
    this.taskSummary = const {},
    this.history = const {'items': <Object?>[], 'nextCursor': null},
    this.failure,
    this.componentsCompleter,
  });

  final List<Map<String, Object?>> components;
  final Map<String, Object?> taskSummary;
  final Map<String, Object?> history;
  final Object? failure;
  final Completer<List<Map<String, Object?>>>? componentsCompleter;

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
    if (failure != null) throw failure!;
    if (name == 'maintenance_list_history') return history;
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    bool forceRefresh = false,
  }) async {
    if (failure != null) throw failure!;
    return componentsCompleter?.future ?? components;
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String periodId = 'current',
    bool forceRefresh = false,
  }) async {
    if (failure != null) throw failure!;
    return taskSummary;
  }
}

Widget catalog(ServiceStateGateway gateway) => MaterialApp(
  theme: maintenanceTheme(),
  home: AssetCatalogScreen(
    key: ValueKey(gateway),
    gateway: gateway,
    onNavigateToTab: (_) {},
    onOpenScanner: () {},
    showBottomNav: false,
  ),
);

Widget actionCenter(ServiceStateGateway gateway) => MaterialApp(
  theme: maintenanceTheme(),
  home: ActionCenterScreen(
    key: ValueKey(gateway),
    gateway: gateway,
    onNavigateToTab: (_) {},
    onOpenScanner: () {},
    showBottomNav: false,
  ),
);

Widget historyScreen(ServiceStateGateway gateway) => MaterialApp(
  theme: maintenanceTheme(),
  home: Scaffold(
    body: HistoryScreen(key: ValueKey(gateway), gateway: gateway),
  ),
);

Future<void> pumpAt(
  WidgetTester tester,
  Widget widget, {
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
      child: widget,
    ),
  );
}

void expectCatalogShell() {
  expect(find.text('Komponen MGRS'), findsOneWidget);
  expect(find.text('Semua'), findsOneWidget);
  expect(find.text('Kepala'), findsOneWidget);
  expect(find.text('Batang'), findsOneWidget);
  expect(find.text('Tabung'), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
}

void expectActionShell() {
  expect(find.text('Pusat Tindakan'), findsOneWidget);
  expect(find.text('Perbarui Kondisi'), findsOneWidget);
  expect(find.text('Servis'), findsWidgets);
  expect(find.byType(TextField), findsOneWidget);
}

void expectHistoryShell() {
  expect(find.text('Riwayat'), findsOneWidget);
  expect(find.text('Jenis aktivitas'), findsOneWidget);
  expect(find.textContaining('Semua tanggal'), findsOneWidget);
}

void main() {
  testWidgets('catalog keeps shell while loading then shows database empty', (
    tester,
  ) async {
    final completer = Completer<List<Map<String, Object?>>>();
    await pumpAt(
      tester,
      catalog(ServiceStateGateway(componentsCompleter: completer)),
    );

    expectCatalogShell();
    expect(find.text('Memuat katalog aset...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    completer.complete(const []);
    await tester.pump();
    await tester.pump();

    expectCatalogShell();
    expect(find.text('Database komponen masih kosong'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog masks errors and preserves shell with recovery', (
    tester,
  ) async {
    await pumpAt(
      tester,
      catalog(ServiceStateGateway(failure: Exception('SQL secret'))),
    );
    await tester.pump();
    await tester.pump();

    expectCatalogShell();
    expect(find.text('Katalog aset gagal dimuat'), findsOneWidget);
    expect(find.text('Muat data terbaru'), findsOneWidget);
    expect(find.textContaining('SQL secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog filtered empty names query and clears it', (
    tester,
  ) async {
    final gateway = ServiceStateGateway(
      components: const [
        {
          'id': 'c-1',
          'nomor_stiker': 'KPL-2026-084',
          'jenis_komponen': 'Kepala',
          'kondisi': 'OK',
        },
      ],
    );
    await pumpAt(tester, catalog(gateway));
    await tester.pumpAndSettle();

    expect(find.text('KPL-2026-084'), findsOneWidget);
    expect(find.text('Layak Pakai'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'TBG-404');
    await tester.pump();

    expectCatalogShell();
    expect(
      find.text(
        'Tidak ada data yang cocok dengan “TBG-404”. Ubah atau hapus pencarian untuk melihat data lain.',
      ),
      findsOneWidget,
    );
    expect(find.text('Hapus pencarian'), findsOneWidget);
    await tester.tap(find.text('Hapus pencarian'));
    await tester.pump();
    expect(find.text('KPL-2026-084'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action center keeps shell for empty and error states', (
    tester,
  ) async {
    await pumpAt(tester, actionCenter(ServiceStateGateway()));
    await tester.pumpAndSettle();
    expectActionShell();
    expect(find.text('Belum ada tugas pemeriksaan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(
      tester,
      actionCenter(ServiceStateGateway(failure: Exception('backend trace'))),
    );
    await tester.pump();
    await tester.pump();
    expectActionShell();
    expect(find.text('Tugas pemeriksaan gagal dimuat'), findsOneWidget);
    expect(
      find.text('Periksa koneksi lalu muat data terbaru.'),
      findsOneWidget,
    );
    expect(find.textContaining('backend trace'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history distinguishes database empty and filtered empty', (
    tester,
  ) async {
    await pumpAt(tester, historyScreen(ServiceStateGateway()));
    await tester.pumpAndSettle();
    expectHistoryShell();
    expect(find.text('Belum ada riwayat aktivitas'), findsOneWidget);

    await tester.tap(find.text('Semua aktivitas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pemeriksaan manual').last);
    await tester.pumpAndSettle();

    expectHistoryShell();
    expect(find.text('Tidak ada riwayat yang sesuai filter'), findsOneWidget);
    expect(find.text('Hapus pencarian'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history shows explicit activity label and component code', (
    tester,
  ) async {
    final gateway = ServiceStateGateway(
      history: const {
        'items': [
          {
            'eventId': 'event-1',
            'code': 'BTG-2026-011',
            'activity': 'periodic_check',
            'recordedAt': '2026-09-14T10:00:00Z',
            'actor': 'Teknisi A',
          },
        ],
        'nextCursor': null,
      },
    );
    await pumpAt(tester, historyScreen(gateway));
    await tester.pumpAndSettle();

    expect(find.text('BTG-2026-011'), findsOneWidget);
    expect(find.text('Pemeriksaan berkala'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('service list shells fit ${width.toInt()} px at 200% text', (
      tester,
    ) async {
      final gateway = ServiceStateGateway();
      await pumpAt(tester, catalog(gateway), width: width, textScale: 2);
      await tester.pumpAndSettle();
      expectCatalogShell();
      expect(tester.takeException(), isNull);

      await pumpAt(tester, actionCenter(gateway), width: width, textScale: 2);
      await tester.pumpAndSettle();
      expectActionShell();
      expect(tester.takeException(), isNull);

      await pumpAt(tester, historyScreen(gateway), width: width, textScale: 2);
      await tester.pumpAndSettle();
      expectHistoryShell();
      expect(tester.takeException(), isNull);
    });
  }
}
