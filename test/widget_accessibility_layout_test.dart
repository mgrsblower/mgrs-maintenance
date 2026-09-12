import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
import 'package:mgrs_maintenance/shared/mgrs_app_shell.dart';

class _MockAccessibilityGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('u-1', 'Tim Lapangan');

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_get_component') {
      return {
        'id': 'comp-101',
        'code': 'KPL-001',
        'kind': 'Kepala',
        'condition': 'OK',
        'usable': 'Ya',
        'impairedFunction': 'Tidak Ada',
        'version': '1',
      };
    }
    if (name == 'maintenance_list_tasks') {
      return {
        'period': {
          'id': '2026-09',
          'opensAt': '2026-09-26T00:00:00Z',
          'closesAt': '2026-09-28T23:59:59Z',
          'snapshotState': 'ready',
        },
        'items': const [],
        'total': 0,
        'completed': 0,
        'nextCursor': null,
      };
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async =>
      const [];
}

Widget fieldShell({Brightness brightness = Brightness.light}) {
  const user = UserProfile('u-1', 'Tim Lapangan');
  return MaterialApp(
    theme: maintenanceTheme(brightness: brightness),
    home: Scaffold(
      body: MGRSAppShell(
        workspace: MgrsWorkspace.field,
        user: user,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        child: const Text('Field Content'),
      ),
    ),
  );
}

Widget fieldDetailScreen({Brightness brightness = Brightness.light}) {
  final gateway = _MockAccessibilityGateway();
  const user = UserProfile('u-1', 'Tim Lapangan');
  return MaterialApp(
    theme: maintenanceTheme(brightness: brightness),
    home: ComponentDetailScreen(
      gateway: gateway,
      user: user,
      id: 'comp-101',
    ),
  );
}

void main() {
  testWidgets(
      'expanded shell uses rail and compact shell uses navigation bar',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(fieldShell());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(fieldShell());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('large text keeps primary action visible', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: fieldDetailScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat Pemeriksaan'), findsOneWidget);
    expect(find.text('Catat Servis'), findsOneWidget);
  });

  testWidgets('dark mode renders without overflow or clipping', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(fieldShell(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
