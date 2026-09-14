import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_app_bar.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_button.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_multiline_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_search_field.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_state_view.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_status_badge.dart';
import 'package:mgrs_maintenance/design_system/layout/mgrs_screen.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';
import 'package:mgrs_maintenance/shared/async_state_view.dart';
import 'package:mgrs_maintenance/shared/condition_badge.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: maintenanceTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('button is 52 high and loading keeps its footprint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var presses = 0;
    final button = MgrsButton.primary(
      label: 'Simpan pemeriksaan',
      icon: Icons.save_outlined,
      onPressed: () => presses++,
    );

    await tester.pumpWidget(host(button));
    final idleSize = tester.getSize(find.byType(FilledButton));
    expect(idleSize.height, MgrsSizes.primaryButton);
    await tester.tap(find.byType(FilledButton));
    expect(presses, 1);

    await tester.pumpWidget(
      host(
        MgrsButton.primary(
          label: 'Simpan pemeriksaan',
          icon: Icons.save_outlined,
          onPressed: () => presses++,
          loading: true,
        ),
      ),
    );
    expect(tester.getSize(find.byType(FilledButton)), idleSize);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      find.bySemanticsLabel('Sedang memproses Simpan pemeriksaan'),
      findsOneWidget,
    );
    await tester.tap(find.byType(FilledButton));
    expect(presses, 1);
    semantics.dispose();
  });

  testWidgets('detail app bar is 56 high and labels icon-only controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Scaffold(
          appBar: MgrsDetailAppBar(
            title: 'Detail komponen',
            onBack: () {},
            actions: [
              MgrsAppBarAction(
                icon: Icons.delete_outline,
                tooltip: 'Hapus komponen',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppBar)).height, MgrsSizes.appBar);
    expect(
      tester.getSize(find.byTooltip('Kembali')),
      const Size.square(MgrsSizes.minTouch),
    );
    expect(
      tester.getSize(find.byTooltip('Hapus komponen')),
      const Size.square(MgrsSizes.minTouch),
    );
    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(find.byTooltip('Hapus komponen'), findsOneWidget);
    final backSemantics = tester.getSemantics(find.bySemanticsLabel('Kembali'));
    expect(backSemantics.label, 'Kembali');
    expect(
      backSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    final actionSemantics = tester.getSemantics(
      find.bySemanticsLabel('Hapus komponen'),
    );
    expect(actionSemantics.label, 'Hapus komponen');
    expect(
      actionSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('search clear is meaningful, semantic, and at least 48 square', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];

    await tester.pumpWidget(
      host(
        SizedBox(
          width: 280,
          child: MgrsSearchField(
            controller: controller,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    expect(find.byTooltip('Hapus pencarian'), findsNothing);

    await tester.enterText(find.byType(TextField), 'blower');
    await tester.pump();
    final clear = find.byTooltip('Hapus pencarian');
    expect(clear, findsOneWidget);
    final clearSemantics = tester.getSemantics(
      find.bySemanticsLabel('Hapus pencarian'),
    );
    expect(clearSemantics.label, 'Hapus pencarian');
    expect(
      clearSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    final clearSize = tester.getSize(
      find.ancestor(of: clear, matching: find.byType(IconButton)),
    );
    expect(clearSize.width, greaterThanOrEqualTo(MgrsSizes.minTouch));
    expect(clearSize.height, greaterThanOrEqualTo(MgrsSizes.minTouch));

    await tester.tap(clear);
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes.last, isEmpty);
    expect(find.byTooltip('Hapus pencarian'), findsNothing);
    semantics.dispose();
  });

  testWidgets('status badges expose text and icon for every tone', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MgrsStatusBadge('OK'),
            MgrsStatusBadge('Rusak Ringan'),
            MgrsStatusBadge('Rusak Berat'),
          ],
        ),
      ),
    );

    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Rusak Ringan'), findsOneWidget);
    expect(find.text('Rusak Berat'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNWidgets(2));
    expect(find.bySemanticsLabel('Status kondisi: OK'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'multiline field shows label, helper, and error without losing text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Suara bearing kasar');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: MgrsMultilineField(
              label: 'Catatan pemeriksaan',
              controller: controller,
              helperText: 'Tuliskan gejala yang terlihat.',
              errorText: 'Catatan perlu diperjelas.',
            ),
          ),
        ),
      );

      expect(find.text('Catatan pemeriksaan'), findsOneWidget);
      expect(find.text('Tuliskan gejala yang terlihat.'), findsNothing);
      expect(find.text('Catatan perlu diperjelas.'), findsOneWidget);
      expect(find.text('Suara bearing kasar'), findsOneWidget);
      expect(find.bySemanticsLabel('Catatan pemeriksaan'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('state actions exist only when they can recover', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        MgrsStateView.error(
          title: 'Data komponen gagal dimuat',
          message: 'Periksa jaringan lalu coba lagi.',
          actionLabel: 'Muat data terbaru',
          onAction: () => retries++,
        ),
      ),
    );
    expect(find.text('Data komponen gagal dimuat'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Muat data terbaru'));
    expect(retries, 1);

    await tester.pumpWidget(
      host(
        const MgrsStateView.empty(
          title: 'Belum ada invoice',
          actionLabel: 'Buat invoice',
        ),
      ),
    );
    expect(find.text('Belum ada invoice'), findsOneWidget);
    expect(find.text('Buat invoice'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Buat invoice'), findsNothing);
  });

  testWidgets('no-results state names query and resets it', (tester) async {
    var resets = 0;
    await tester.pumpWidget(
      host(MgrsStateView.noResults(query: 'CMP-404', onReset: () => resets++)),
    );

    expect(find.textContaining('CMP-404'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus pencarian'));
    expect(resets, 1);
  });

  testWidgets(
    'screen derives gutter and max width from available constraints',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(
        MaterialApp(
          theme: maintenanceTheme(),
          home: const MgrsScreen(
            child: SizedBox(key: ValueKey('content'), height: 900),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('content'))).width, 280);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1000, 700));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('content'))).width,
        MgrsSizes.maxContentWidth,
      );
    },
  );

  testWidgets('screen remains scrollable at 320 width and 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 600));

    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const MgrsScreen(
            child: Column(
              children: [
                Text(
                  'Catatan pemeriksaan komponen dengan rincian yang panjang',
                ),
                SizedBox(height: 700),
                Text('Konten terakhir'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Konten terakhir'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy condition badge preserves visible condition mapping', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConditionBadge('OK'),
            ConditionBadge('Rusak Ringan'),
            ConditionBadge('Layak Pakai'),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNWidgets(2));
    final legacyDanger = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Layak Pakai'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (legacyDanger.decoration as BoxDecoration).color,
      MgrsColors.dangerSoft,
    );
    expect(
      find.bySemanticsLabel('Status kondisi: Rusak Ringan'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('legacy async view keeps success and retry behavior', (
    tester,
  ) async {
    var retries = 0;
    final failure = Completer<int>();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Scaffold(
          body: AsyncStateView<int>(
            future: failure.future,
            retry: () => retries++,
            builder: (value) => Text('Nilai $value'),
          ),
        ),
      ),
    );
    failure.completeError(const AppFailure('network'));
    await tester.pump();
    expect(find.byType(MgrsStateView), findsOneWidget);
    expect(
      find.text('Koneksi terputus. Periksa jaringan lalu coba lagi.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
    expect(retries, 1);

    final pending = Completer<int>();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Scaffold(
          body: AsyncStateView<int>(
            future: pending.future,
            retry: () {},
            builder: (value) => Text('Nilai $value'),
          ),
        ),
      ),
    );
    expect(find.text('Memuat data...'), findsOneWidget);
    pending.complete(7);
    await tester.pump();
    expect(find.text('Nilai 7'), findsOneWidget);
  });
}
