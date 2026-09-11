import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/schedule/component_picker_sheet.dart';

class MockPickerGateway extends MaintenanceGateway {
  @override
  Stream<void> get authChanges => const Stream.empty();
  @override
  Future<UserProfile?> profile() async => const UserProfile('u-1', 'Tim Pemasangan');
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
  }) async {
    return [
      {'nomor_stiker': 'K-01', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      {'nomor_stiker': 'K-02', 'jenis_komponen': 'Kepala', 'kondisi': 'OK', 'boleh_dipakai': 'Ya'},
      {'nomor_stiker': 'K-03', 'jenis_komponen': 'Kepala', 'kondisi': 'Service', 'boleh_dipakai': 'Tidak'},
    ];
  }
}

void main() {
  testWidgets('ComponentPickerSheet sorts by least used and allows selection', (tester) async {
    final gateway = MockPickerGateway();
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await showComponentPickerSheet(
                  context,
                  gateway: gateway,
                  kind: 'Kepala',
                  usageCounts: const {'K-01': 10, 'K-02': 2},
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.textContaining('Pilih Kepala Blower'), findsOneWidget);

    // K-02 (2x pakai) should appear before K-01 (10x pakai)
    expect(find.text('K-02'), findsOneWidget);
    expect(find.text('2x pakai'), findsOneWidget);
    expect(find.text('K-01'), findsOneWidget);
    expect(find.text('10x pakai'), findsOneWidget);

    // K-03 is not usable (boleh_dipakai: Tidak), should be filtered out
    expect(find.text('K-03'), findsNothing);

    // Tap K-02
    await tester.tap(find.text('K-02'));
    await tester.pumpAndSettle();

    expect(selected, equals('K-02'));
  });
}
