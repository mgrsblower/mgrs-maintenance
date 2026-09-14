import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';
import 'package:mgrs_maintenance/shared/bottom_nav_bar.dart';

void main() {
  const picItems = [
    AppNavItem(
      label: 'Beranda',
      activeIcon: Icons.space_dashboard_rounded,
      inactiveIcon: Icons.space_dashboard_outlined,
    ),
    AppNavItem(
      label: 'Orderan',
      activeIcon: Icons.event_note_rounded,
      inactiveIcon: Icons.event_note_outlined,
    ),
    AppNavItem(
      label: 'Invoice',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
  ];

  Widget host({
    int currentIndex = 0,
    ValueChanged<int>? onNavigate,
    VoidCallback? onScanner,
    List<AppNavItem>? items,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return MaterialApp(
      theme: maintenanceTheme(),
      home: MediaQuery(
        data: MediaQueryData(padding: padding),
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: currentIndex,
            onNavigateToTab: onNavigate ?? (_) {},
            onOpenScanner: onScanner,
            items: items,
          ),
        ),
      ),
    );
  }

  testWidgets('service and PIC destinations retain their role labels', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Aset'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);

    await tester.pumpWidget(host(items: picItems));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Orderan'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Aset'), findsNothing);
  });

  testWidgets(
    'selected destination is semantic and navigation stays operable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var selectedIndex = -1;
      await tester.pumpWidget(
        host(currentIndex: 1, onNavigate: (index) => selectedIndex = index),
      );

      final selected = tester.getSemantics(find.bySemanticsLabel('Aset'));
      expect(
        selected.getSemanticsData().flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        selected.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isTrue,
      );

      final activeIcon = tester.widget<Icon>(
        find.byIcon(Icons.inventory_2_rounded),
      );
      final inactiveIcon = tester.widget<Icon>(
        find.byIcon(Icons.home_outlined),
      );
      expect(activeIcon.color, MgrsColors.surface);
      expect(inactiveIcon.color, const Color(0xFFA8A8A8));

      await tester.tap(find.bySemanticsLabel('Servis'));
      expect(selectedIndex, 2);
      semantics.dispose();
    },
  );

  testWidgets('dock content is 68 high excluding bottom safe area', (
    tester,
  ) async {
    await tester.pumpWidget(host(padding: const EdgeInsets.only(bottom: 24)));

    expect(
      tester
          .getSize(find.byKey(const ValueKey('bottom-navigation-content')))
          .height,
      68.0,
    );
    expect(
      tester.getSize(find.byType(AppBottomNavBar)).height,
      68.0 + 24 + MgrsSpacing.sm,
    );
  });

  testWidgets('scanner is optional, labeled, and invokes its callback once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var opens = 0;
    await tester.pumpWidget(host(onScanner: () => opens++));

    final scanner = find.byKey(const ValueKey('scanner-action'));
    expect(scanner, findsOneWidget);
    expect(find.byTooltip('Buka pemindai kode'), findsOneWidget);
    expect(find.bySemanticsLabel('Buka pemindai kode'), findsOneWidget);
    expect(tester.getSize(scanner), const Size.square(56));
    await tester.tap(scanner);
    expect(opens, 1);

    await tester.pumpWidget(host());
    expect(scanner, findsNothing);
    expect(find.bySemanticsLabel('Buka pemindai kode'), findsNothing);
    semantics.dispose();
  });

  testWidgets('horizontal scrub selects the destination under release', (
    tester,
  ) async {
    var selectedIndex = -1;
    await tester.pumpWidget(host(onNavigate: (index) => selectedIndex = index));

    final dock = find.byKey(const ValueKey('bottom-navigation-content'));
    final start = tester.getTopLeft(dock) + const Offset(40, 34);
    final end = tester.getTopRight(dock) + const Offset(-110, 34);
    await tester.dragFrom(start, end - start);
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
  });
}
