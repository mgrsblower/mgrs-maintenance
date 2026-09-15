import 'package:flutter/foundation.dart';

import '../../app/gateway.dart';
import '../components/component.dart';

enum ScanPhase {
  camera,
  lookingUp,
  permissionDenied,
  unavailable,
  notFound,
  ambiguous,
  networkFailure,
  result,
}

@immutable
class ScanState {
  const ScanState({
    required this.phase,
    this.lastSubmittedCode,
    this.component,
    this.message,
  });

  final ScanPhase phase;
  final String? lastSubmittedCode;
  final Component? component;
  final String? message;

  bool get allowsManualEntry => phase != ScanPhase.result;
}

class ScanStateMachine extends ChangeNotifier {
  ScanStateMachine({Component? initialComponent})
    : _state = initialComponent == null
          ? const ScanState(phase: ScanPhase.camera)
          : ScanState(
              phase: ScanPhase.result,
              component: initialComponent,
              lastSubmittedCode: initialComponent.code,
            );

  ScanState _state;
  ScanState get state => _state;

  bool beginLookup(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty || _state.phase == ScanPhase.lookingUp) return false;
    _setState(ScanState(phase: ScanPhase.lookingUp, lastSubmittedCode: code));
    return true;
  }

  void complete(Object? response) {
    final code = _state.lastSubmittedCode;
    if (response is! List || response.isEmpty) {
      _setState(
        ScanState(
          phase: ScanPhase.notFound,
          lastSubmittedCode: code,
          message: 'Komponen tidak ditemukan. Periksa kode lalu coba lagi.',
        ),
      );
      return;
    }
    if (response.length > 1) {
      _setState(
        ScanState(
        phase: ScanPhase.ambiguous,
        lastSubmittedCode: code,
        message: 'Barcode tidak unik. Masukkan nomor stiker lengkap.',
        ),
      );
      return;
    }

    final rawComponent = response.single;
    final component = switch (rawComponent) {
      Component value => value,
      Map value => Component.fromMap(Map<String, Object?>.from(value)),
      _ => null,
    };
    if (component == null) {
      _setState(
        ScanState(
          phase: ScanPhase.notFound,
          lastSubmittedCode: code,
          message: 'Komponen tidak ditemukan. Periksa kode lalu coba lagi.',
        ),
      );
      return;
    }
    _setState(
      ScanState(
        phase: ScanPhase.result,
        lastSubmittedCode: code,
        component: component,
      ),
    );
  }

  void fail(Object error) {
    if (error is AppFailure && error.code == 'not_found') {
      complete(const []);
      return;
    }
    if (error is AppFailure && error.code == 'ambiguous') {
      complete(const [{}, {}]);
      return;
    }
    _setState(
      ScanState(
        phase: ScanPhase.networkFailure,
        lastSubmittedCode: _state.lastSubmittedCode,
        message: 'Gangguan koneksi. Periksa jaringan lalu coba lagi.',
      ),
    );
  }

  void cameraFailure({required bool permissionDenied}) {
    _setState(
      ScanState(
        phase: permissionDenied
            ? ScanPhase.permissionDenied
            : ScanPhase.unavailable,
        lastSubmittedCode: _state.lastSubmittedCode,
        message: permissionDenied
            ? 'Izinkan akses kamera untuk memindai barcode, atau masukkan kode secara manual.'
            : 'Kamera tidak dapat digunakan. Masukkan kode secara manual untuk melanjutkan.',
      ),
    );
  }

  void reset() {
    _setState(const ScanState(phase: ScanPhase.camera));
  }

  void _setState(ScanState value) {
    _state = value;
    notifyListeners();
  }
}
