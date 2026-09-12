import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseGateway _gateway(
  Future<http.Response> Function(http.Request request) handler,
) {
  return SupabaseGateway(
    SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient(handler),
    ),
  );
}

void main() {
  test('successful empty upcoming-order response remains empty', () async {
    final gateway = _gateway(
      (request) async => http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    );
    addTearDown(gateway.client.dispose);

    expect(await gateway.fetchUpcomingOrders(), isEmpty);
  });

  test('upcoming-order backend failure reaches the caller', () async {
    final gateway = _gateway(
      (request) async => http.Response(
        '{"code":"XX000","message":"order service unavailable","details":null,"hint":null}',
        500,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    );
    addTearDown(gateway.client.dispose);

    await expectLater(
      gateway.fetchUpcomingOrders(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'order service unavailable',
        ),
      ),
    );
  });
}
