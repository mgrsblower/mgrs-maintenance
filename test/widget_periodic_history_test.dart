import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/history/history_screen.dart';
import 'package:mgrs_maintenance/features/schedule/component_picker_sheet.dart';
import 'package:mgrs_maintenance/features/schedule/schedule_screen.dart';

class _MockPeriodicGateway extends MaintenanceGateway {
  _MockPeriodicGateway({
    this.tasks = const [],
    this.history = const [],
  });

  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> history;

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async =>
      const UserProfile('user-1', 'Tim Lapangan');

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name == 'maintenance_list_tasks') {
      return {
        'period': {
          'id': '2026-09',
          'opensAt': '2026-09-26T00:00:00Z',
          'closesAt': '2026-09-28T23:59:59Z',
          'snapshotState': 'ready',
        },
        'items': tasks,
        'total': tasks.length,
        'completed': tasks
            .where((t) =>
                t['status'] == 'completed' || t['status'] == 'completed_late')
            .length,
        'nextCursor': null,
      };
    }
    if (name == 'maintenance_list_history') {
      return {
        'items': history,
        'nextCursor': null,
      };
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    String? condition,
    bool forceRefresh = false,
  }) async {
    return [
      {
        'nomor_stiker': 'K-01',
        'jenis_komponen': 'Kepala',
        'kondisi': 'OK',
        'boleh_dipakai': 'Ya',
      },
    ];
  }
}

Widget periodicTask({required String condition, required bool completed}) {
  final task = {
    'id': 'task-1',
    'periodId': '2026-09',
    'componentId': 'comp-1',
    'code': 'KPL-001',
    'kind': 'Kepala',
    'status': completed ? 'completed' : 'due',
    'condition': condition,
    'completedAt': completed ? '2026-09-26T10:00:00Z' : null,
  };
  final gateway = _MockPeriodicGateway(tasks: [task]);
  return MaterialApp(
    theme: maintenanceTheme(),
    home: Scaffold(
      body: ScheduleScreen(
        gateway: gateway,
        user: const UserProfile('user-1', 'Tim Lapangan'),
      ),
    ),
  );
}

Widget historyWithData(List<Map<String, Object?>> items) {
  final gateway = _MockPeriodicGateway(history: items);
  return MaterialApp(
    theme: maintenanceTheme(),
    home: Scaffold(
      body: HistoryScreen(
        gateway: gateway,
        user: const UserProfile('user-1', 'Tim Lapangan'),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'damaged component can be completed without showing healthy state',
      (tester) async {
    await tester.pumpWidget(
      periodicTask(condition: 'Rusak Berat', completed: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selesai diperiksa'), findsOneWidget);
    expect(find.text('Kondisi baik'), findsNothing);
  });

  testWidgets('history empty state is distinct from loading', (tester) async {
    await tester.pumpWidget(historyWithData(const []));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada riwayat'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('periodic screen controls meet 48dp target', (tester) async {
    final gateway = _MockPeriodicGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Scaffold(
          body: ScheduleScreen(
            gateway: gateway,
            user: const UserProfile('user-1', 'Tim Lapangan'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final prevMonth = find.byTooltip('Bulan sebelumnya');
    final nextMonth = find.byTooltip('Bulan berikutnya');
    final refresh = find.byTooltip('Perbarui jadwal');
    final search = find.byTooltip('Cari komponen');

    expect(tester.getSize(prevMonth).shortestSide, greaterThanOrEqualTo(48));
    expect(tester.getSize(nextMonth).shortestSide, greaterThanOrEqualTo(48));
    expect(tester.getSize(refresh).shortestSide, greaterThanOrEqualTo(48));
    expect(tester.getSize(search).shortestSide, greaterThanOrEqualTo(48));
  });

  testWidgets('history screen controls meet 48dp target', (tester) async {
    await tester.pumpWidget(historyWithData(const []));
    await tester.pumpAndSettle();

    final refresh = find.byTooltip('Perbarui riwayat');
    expect(tester.getSize(refresh).shortestSide, greaterThanOrEqualTo(48));

    final dateRangeButton = find.byType(OutlinedButton);
    expect(tester.getSize(dateRangeButton).height, greaterThanOrEqualTo(48));
  });

  testWidgets('component picker sheet close button has tooltip and 48dp target',
      (tester) async {
    final gateway = _MockPeriodicGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: maintenanceTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showComponentPickerSheet(
                context,
                gateway: gateway,
                kind: 'Kepala',
                usageCounts: const {},
              ),
              child: const Text('Buka Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Picker'));
    await tester.pumpAndSettle();

    final closeBtn = find.byTooltip('Tutup');
    expect(closeBtn, findsOneWidget);
    expect(tester.getSize(closeBtn).shortestSide, greaterThanOrEqualTo(48));
  });
}
