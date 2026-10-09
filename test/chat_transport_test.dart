import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tutor_preethi/services/chat_transport.dart';

void main() {
  test('network and busy retries preserve the exact request identity', () async {
    final bodies = <String>[];
    final client = MockClient((request) async {
      bodies.add(request.body);
      if (bodies.length == 1) throw http.ClientException('lost connection');
      if (bodies.length == 2) return http.Response('busy', 503);
      return http.Response('answer', 200);
    });
    final response = await sendChatWithRetry(client: client,
        endpoint: Uri.parse('https://example.test/ask'), token: 'test',
        payload: {'client_request_id': newChatRequestId(), 'question':'test'},
        pause: (_) async {});
    expect(response.statusCode, 200);
    expect(bodies.length, 3);
    expect(bodies.toSet().length, 1);
    expect(jsonDecode(bodies.first)['client_request_id'], matches(RegExp(r'^[a-f0-9-]{36}$')));
    client.close();
  });

  test('daily and conversation limits are not retried', () async {
    for (final status in [403, 409]) {
      var calls = 0;
      final client = MockClient((_) async { calls++; return http.Response('limit', status); });
      await sendChatWithRetry(client: client, endpoint: Uri.parse('https://example.test/ask'),
          token:'test', payload:{'client_request_id':newChatRequestId()}, pause: (_) async {});
      expect(calls, 1);
      client.close();
    }
  });

  test('pending duplicates retry but attempts remain bounded', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('pending', 409, headers:{'x-chat-error':'request_pending'});
    });
    final response = await sendChatWithRetry(client:client, endpoint:Uri.parse('https://example.test/ask'),
        token:'test', payload:{'client_request_id':newChatRequestId()}, pause: (_) async {});
    expect(response.statusCode, 409);
    expect(calls, 4);
    client.close();
  });
}
