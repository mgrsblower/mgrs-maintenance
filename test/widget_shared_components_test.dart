import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/shared/async_state_view.dart';
import 'package:mgrs_maintenance/shared/mgrs_components.dart';
import 'package:mgrs_maintenance/shared/mgrs_app_shell.dart';
import 'package:mgrs_maintenance/shared/pressable.dart';

void main() {
  testWidgets('theme gives primary controls a 48dp minimum', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: FilledButton(onPressed: () {}, child: const Text('Simpan')),
      ),
    );

    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('theme exposes semantic light and dark roles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: const SizedBox(key: Key('theme-home')),
      ),
    );
    final lightContext = tester.element(find.byKey(const Key('theme-home')));
    expect(Theme.of(lightContext).colorScheme.primary, AppTokens.actionBlue);
    expect(Theme.of(lightContext).scaffoldBackgroundColor, AppTokens.canvas);

    final darkTheme = maintenanceDarkTheme();
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.colorScheme.primary, AppTokens.actionBlueFocus);
    expect(darkTheme.scaffoldBackgroundColor, AppTokens.surfaceBlack);
  });

  testWidgets('adaptive navigation uses bar on compact and rail when expanded',
      (tester) async {
    var selected = -1;
    Widget buildAt(double width) => MaterialApp(
          theme: maintenanceTheme(),
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 800,
              child: AdaptiveNavigation(
                workspace: MgrsWorkspace.pic,
                selectedIndex: 0,
                onDestinationSelected: (value) => selected = value,
              ),
            ),
          ),
        );

    await tester.pumpWidget(buildAt(500));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.text('Orderan'));
    expect(selected, 1);

    await tester.pumpWidget(buildAt(600));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('workspace switcher presents exactly the two workspace labels',
      (tester) async {
    MgrsWorkspace? changed;
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: WorkspaceSwitcher(
          workspace: MgrsWorkspace.pic,
          onWorkspaceChanged: (value) => changed = value,
        ),
      ),
    );

    expect(find.text('PIC MGRS'), findsOneWidget);
    expect(find.text('Tim Lapangan'), findsOneWidget);
    await tester.tap(find.text('Tim Lapangan'));
    expect(changed, MgrsWorkspace.field);
  });

  testWidgets('admin shell requires and renders its workspace switcher',
      (tester) async {
    const admin = UserProfile('admin', 'Admin', fullName: 'Admin MGRS');
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: MGRSAppShell(
          workspace: MgrsWorkspace.pic,
          user: admin,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const SizedBox(),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());

    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: MGRSAppShell(
          workspace: MgrsWorkspace.pic,
          user: admin,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          onWorkspaceChanged: (_) {},
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
    expect(find.byType(WorkspaceSwitcher), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(NavigationRail),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
  });

  testWidgets('async state view renders an explicit empty builder',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: AsyncStateView<List<String>>(
          future: Future.value(const <String>[]),
          retry: () {},
          isEmpty: (value) => value.isEmpty,
          empty: () => const Text('Tidak ada order'),
          builder: (value) => Text(value.single),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada order'), findsOneWidget);
  });

  testWidgets('explicit empty predicate overrides compatibility inference',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: AsyncStateView<List<String>>(
          future: Future.value(const <String>[]),
          retry: () {},
          isEmpty: (_) => false,
          empty: () => const Text('Tidak ada order'),
          builder: (_) => const Text('Daftar sengaja kosong'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daftar sengaja kosong'), findsOneWidget);
    expect(find.text('Tidak ada order'), findsNothing);
  });

  testWidgets('explicit predicate can keep a nullable null value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: AsyncStateView<String?>(
          future: Future<String?>.value(null),
          retry: () {},
          isEmpty: (_) => false,
          builder: (value) => Text(value ?? 'Nilai null dipertahankan'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nilai null dipertahankan'), findsOneWidget);
  });

  testWidgets('async state view renders error and permission states',
      (tester) async {
    final permission = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: AsyncStateView<String>(
          future: permission.future,
          retry: () {},
          builder: Text.new,
        ),
      ),
    );
    permission.completeError(const AppFailure('forbidden'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Akses tidak tersedia'), findsOneWidget);

    final failure = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: AsyncStateView<String>(
          future: failure.future,
          retry: () {},
          error: (error) => const Text('Coba kembali nanti'),
          builder: Text.new,
        ),
      ),
    );
    failure.completeError(const AppFailure('network'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Coba kembali nanti'), findsOneWidget);
  });

  testWidgets('pressable exposes button semantics and respects reduced motion',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PressableScale(
            onTap: () => taps++,
            child: const Text('Tekan'),
          ),
        ),
      ),
    );

    expect(find.byType(Transform), findsNothing);
    final semantics = tester.getSemantics(find.text('Tekan'));
    expect(semantics.flagsCollection.isButton, isTrue);
    await tester.tap(find.text('Tekan'));
    expect(taps, 1);
  });

  testWidgets('pressable meets the touch target without affecting passive layout',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Column(
          children: [
            PressableScale(
              key: const Key('interactive-pressable'),
              onTap: () {},
              child: const SizedBox(width: 12, height: 20),
            ),
            PressableScale(
              key: const Key('passive-pressable'),
              child: const SizedBox(width: 12, height: 20),
            ),
          ],
        ),
      ),
    );
    final interactiveSize =
        tester.getSize(find.byKey(const Key('interactive-pressable')));
    expect(interactiveSize.width, greaterThanOrEqualTo(48));
    expect(interactiveSize.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byKey(const Key('passive-pressable'))),
      const Size(12, 20),
    );
  });

  testWidgets('disabled pressable keeps its target and disabled semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: PressableScale(
          key: const Key('disabled-pressable'),
          enabled: false,
          onTap: () {},
          child: const SizedBox(width: 12, height: 20),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(const Key('disabled-pressable')));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    final semantics = tester.getSemantics(
      find.byKey(const Key('disabled-pressable')),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, isNot(isTrue));
  });

  testWidgets('save action bar owns submitting and retry presentation',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: SaveActionBar(
          onSave: () {},
          isSubmitting: true,
          onRetry: () => retried = true,
          errorMessage: 'gagal',
        ),
      ),
    );
    expect(find.text('Menyimpan…'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: SaveActionBar(
          onSave: () {},
          onRetry: () => retried = true,
          errorMessage: 'gagal',
        ),
      ),
    );
    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });
}
