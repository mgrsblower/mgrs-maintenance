import '../../app/gateway.dart';

enum SubmissionState {
  idle,
  submitting,
  succeeded,
  conflict,
  uncertain,
  failed,
}

class SubmissionController {
  SubmissionController(this.gateway);
  final MaintenanceGateway gateway;
  SubmissionState state = SubmissionState.idle;
  Map<String, Object?>? command, receipt;
  Object? error;
  bool get locked =>
      state == SubmissionState.submitting || state == SubmissionState.uncertain;

  Future<void> submit(Map<String, Object?> value) async {
    if (locked || state == SubmissionState.succeeded) return;
    command = Map.unmodifiable(value);
    await _send();
  }

  Future<void> recover() async {
    if (state != SubmissionState.uncertain || command == null) return;
    state = SubmissionState.submitting;
    error = null;
    try {
      final found = await gateway.rpc('maintenance_request_result', {
        'p_request_id': command!['requestId'],
      });
      if (found != null) {
        receipt = jsonObject(found);
        state = SubmissionState.succeeded;
      } else {
        await _send();
      }
    } catch (e) {
      error = e;
      state = SubmissionState.uncertain;
    }
  }

  Future<void> _send() async {
    state = SubmissionState.submitting;
    error = null;
    try {
      receipt = jsonObject(
        await gateway.rpc('maintenance_submit', {'p_command': command}),
      );
      state = SubmissionState.succeeded;
    } catch (e) {
      error = e;
      if (e is AppFailure && e.code == 'conflict') {
        state = SubmissionState.conflict;
      } else if (e is AppFailure &&
          const {
            'invalid_input',
            'not_found',
            'task_already_completed',
            'task_not_open',
            'component_unavailable',
            'request_mismatch',
            'unauthenticated',
            'forbidden',
            'unavailable',
          }.contains(e.code)) {
        state = SubmissionState.failed;
      } else {
        state = SubmissionState.uncertain;
      }
    }
  }
}
