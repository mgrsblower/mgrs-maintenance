import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';

class DemoGateway extends MaintenanceGateway {
  String condition = 'Rusak Ringan';
  String usable = 'Tidak';
  String version = 'v1';
  final events = <Map<String, Object?>>[];

  Map<String, Object?> get component => {
    'id': 'component-1',
    'code': 'LOCAL-STICKER-KEPALA-001',
    'kind': 'Kepala',
    'condition': condition,
    'usable': usable,
    'impairedFunction': condition == 'OK' ? 'Tidak Ada' : 'Pengunci',
    'note': condition == 'OK' ? 'Siap digunakan' : 'Perlu diperiksa',
    'version': version,
    'lastCheckingAt': '2026-09-07T02:00:00Z',
    'lastServiceAt': null,
  };

  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('user-1', 'Admin');
  @override
  Future<void> signIn(String identifier, String password) async {}
  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    switch (name) {
      case 'maintenance_lookup_component':
        return [component];
      case 'maintenance_get_component':
        return component;
      case 'maintenance_submit':
        final command = Map<String, Object?>.from(params['p_command']! as Map);
        final before = component;
        condition = command['condition']! as String;
        usable = command['usable']! as String;
        version = 'v2';
        final eventId = 'event-${events.length + 1}';
        events.insert(0, {
          'eventId': eventId,
          'componentId': 'component-1',
          'code': 'LOCAL-STICKER-KEPALA-001',
          'kind': 'Kepala',
          'activity': command['activity'],
          'actor': 'Admin QA',
          'recordedAt': '2026-09-07T03:00:00Z',
          'periodId': command['activity'] == 'periodic_check'
              ? '2026-09'
              : null,
          'before': before,
          'after': component,
          'legacy': false,
          'costRecorded': false,
          'note': command['eventNote'],
          'problem': command['problem'],
          'action': command['action'],
        });
        return {
          'eventId': eventId,
          'requestId': command['requestId'],
          'componentId': 'component-1',
          'version': version,
          'recordedAt': '2026-09-07T03:00:00Z',
          'completedTaskId': command['taskId'],
        };
      case 'maintenance_request_result':
        return null;
      case 'maintenance_list_tasks':
        return {
          'period': {
            'id': '2026-09',
            'opensAt': '2026-09-26T00:00:00+07:00',
            'closesAt': '2026-09-28T00:00:00+07:00',
            'serverNow': '2026-09-26T02:00:00+07:00',
            'snapshotState': 'ready',
          },
          'total': 1,
          'completed': 0,
          'items': [
            {
              'id': 'task-1',
              'periodId': '2026-09',
              'componentId': 'component-1',
              'code': 'LOCAL-STICKER-KEPALA-001',
              'kind': 'Kepala',
              'status': 'due',
              'completedAt': null,
            },
          ],
          'nextCursor': null,
        };
      case 'maintenance_list_history':
        return {'items': events, 'nextCursor': null};
      case 'maintenance_get_history':
        return events.firstWhere(
          (event) => event['eventId'] == params['p_event_id'],
        );
      default:
        throw StateError('Unexpected RPC $name');
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('manual scan, update, schedule, and history work end to end', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    final gateway = DemoGateway();
    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    expect(find.text('Cek kondisi komponen'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'LOCAL-STICKER-KEPALA-001',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cari komponen'));
    await tester.pumpAndSettle();
    expect(find.text('Detail komponen'), findsOneWidget);
    expect(find.text('Rusak Ringan'), findsWidgets);

    final checkingButton = find.widgetWithText(
      FilledButton,
      'Catat pemeriksaan',
    );
    await tester.scrollUntilVisible(
      checkingButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(checkingButton);
    await tester.pumpAndSettle();
    final conditionField = find.byType(DropdownButtonFormField<String>).at(0);
    await tester.ensureVisible(conditionField);
    await tester.tap(conditionField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    final usableField = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(usableField);
    await tester.tap(usableField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tinjau hasil'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan hasil ini?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Detail komponen'), findsOneWidget);
    expect(find.text('OK'), findsWidgets);

    final serviceButton = find.widgetWithText(OutlinedButton, 'Catat servis');
    await tester.scrollUntilVisible(
      serviceButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(serviceButton);
    await tester.pumpAndSettle();
    expect(find.text('Catat servis'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'Pengunci aus');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Membersihkan dan mengencangkan pengunci',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final serviceCondition = find.byType(DropdownButtonFormField<String>).at(0);
    await tester.ensureVisible(serviceCondition);
    await tester.tap(serviceCondition);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    final serviceUsable = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(serviceUsable);
    await tester.tap(serviceUsable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya').last);
    await tester.pumpAndSettle();
    final serviceReview = find.widgetWithText(FilledButton, 'Tinjau hasil');
    await tester.scrollUntilVisible(
      serviceReview,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(serviceReview);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Detail komponen'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berkala'));
    await tester.pumpAndSettle();
    expect(find.text('1 pemeriksaan selesai sesuai filter.'), findsNothing);
    expect(
      find.text('0 dari 1 pemeriksaan selesai sesuai filter.'),
      findsOneWidget,
    );
    expect(find.text('LOCAL-STICKER-KEPALA-001'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Pemeriksaan manual'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
    await tester.tap(find.text('LOCAL-STICKER-KEPALA-001').last);
    await tester.pumpAndSettle();
    expect(find.text('Detail riwayat'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await binding.takeScreenshot('maintenance-history-detail');
    final correctionButton = find.text('Buat catatan koreksi');
    await tester.scrollUntilVisible(
      correctionButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(correctionButton, findsOneWidget);
    await tester.ensureVisible(correctionButton);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('maintenance-correction-action');
  });
}
