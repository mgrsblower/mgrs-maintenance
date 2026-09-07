import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/maintenance/submission_controller.dart';
import 'widget_test.dart' show SignedOutGateway;

class SubmissionGateway extends SignedOutGateway {
  final calls = <Map<String, Object?>>[];
  bool committed = false, receiptAvailable = false;
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    calls.add({'name': name, ...params});
    if (name == 'maintenance_request_result') {
      return receiptAvailable ? {'eventId': 'event-1'} : null;
    }
    if (!committed) {
      committed = true;
      throw const AppFailure('network');
    }
    return {'eventId': 'event-1'};
  }
}

void main() {
  test(
    'lost response keeps payload immutable and retries same request after receipt lookup',
    () async {
      final gateway = SubmissionGateway();
      final controller = SubmissionController(gateway);
      final input = <String, Object?>{
        'requestId': 'request-1',
        'condition': 'OK',
      };
      await controller.submit(input);
      input['condition'] = 'Hilang';
      expect(controller.state, SubmissionState.uncertain);
      await controller.submit({'requestId': 'request-2'});
      expect(gateway.calls.length, 1);
      await controller.recover();
      expect(controller.state, SubmissionState.succeeded);
      expect(gateway.calls[1]['name'], 'maintenance_request_result');
      expect(gateway.calls[2]['p_command'], {
        'requestId': 'request-1',
        'condition': 'OK',
      });
    },
  );
  test('known receipt resolves timeout without a second mutation', () async {
    final gateway = SubmissionGateway()..receiptAvailable = true;
    final controller = SubmissionController(gateway);
    await controller.submit({'requestId': 'request-1'});
    await controller.recover();
    expect(controller.state, SubmissionState.succeeded);
    expect(gateway.calls.length, 2);
  });
}
