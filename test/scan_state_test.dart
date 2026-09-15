import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/component.dart';
import 'package:mgrs_maintenance/features/scan/scan_state.dart';

Component _component() => Component.fromMap(const {
  'id': 'c-1',
  'nomor_stiker': 'KPL-001',
  'jenis_komponen': 'Kepala',
  'kondisi': 'OK',
  'boleh_dipakai': 'Ya',
  'fungsi_terganggu': 'Tidak Ada',
});

void main() {
  group('ScanStateMachine', () {
    test('starts in camera phase and trims submitted code', () {
      final machine = ScanStateMachine();

      expect(machine.state.phase, ScanPhase.camera);
      expect(machine.beginLookup('  KPL-001  '), isTrue);
      expect(machine.state.phase, ScanPhase.lookingUp);
      expect(machine.state.lastSubmittedCode, 'KPL-001');
    });

    test('rejects a second lookup while one is running', () {
      final machine = ScanStateMachine();

      expect(machine.beginLookup('KPL-001'), isTrue);
      expect(machine.beginLookup('KPL-002'), isFalse);
      expect(machine.state.lastSubmittedCode, 'KPL-001');
    });

    test('maps lookup outcomes to explicit phases', () {
      final machine = ScanStateMachine();

      machine.beginLookup('missing');
      machine.complete(const []);
      expect(machine.state.phase, ScanPhase.notFound);
      expect(machine.state.allowsManualEntry, isTrue);

      machine.beginLookup('duplicate');
      machine.complete(const [{}, {}]);
      expect(machine.state.phase, ScanPhase.ambiguous);
      expect(machine.state.allowsManualEntry, isTrue);

      machine.beginLookup('KPL-001');
      machine.complete([_component()]);
      expect(machine.state.phase, ScanPhase.result);
      expect(machine.state.component?.code, 'KPL-001');
    });

    test('maps network and unknown failures without technical details', () {
      final machine = ScanStateMachine();

      machine.beginLookup('KPL-001');
      machine.fail(const AppFailure('network'));
      expect(machine.state.phase, ScanPhase.networkFailure);
      expect(machine.state.message, contains('koneksi'));

      machine.beginLookup('KPL-002');
      machine.fail(Exception('SQLSTATE 42P01 relation components'));
      expect(machine.state.phase, ScanPhase.networkFailure);
      expect(machine.state.message, isNot(contains('SQLSTATE')));
      expect(machine.state.message, isNot(contains('Exception')));
    });

    test('maps camera failures and can reset for the next scan', () {
      final machine = ScanStateMachine();

      machine.cameraFailure(permissionDenied: true);
      expect(machine.state.phase, ScanPhase.permissionDenied);
      expect(machine.state.allowsManualEntry, isTrue);

      machine.cameraFailure(permissionDenied: false);
      expect(machine.state.phase, ScanPhase.unavailable);

      machine.reset();
      expect(machine.state.phase, ScanPhase.camera);
      expect(machine.state.lastSubmittedCode, isNull);
    });
  });
}
