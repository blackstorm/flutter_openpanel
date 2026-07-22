import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openpanel_flutter/openpanel_flutter.dart';
import 'package:openpanel_flutter/src/models/post_event_payload.dart';
import 'package:openpanel_flutter/src/services/openpanel_http_client.dart';

void main() {
  group('OpenpanelHttpClient.event', () {
    test('accepts a JSON object response body', () async {
      var posts = 0;
      final client = _client((request) async {
        posts += 1;
        expect(request.url.path, endsWith('/track'));
        expect(jsonDecode(request.body), isA<Map<String, dynamic>>());
        return http.Response(
          '{"deviceId":"d1","sessionId":"s1"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await client.event(payload: _payload());
      expect(posts, 1);
      client.dispose();
    });

    test('accepts a plain string response body', () async {
      final client = _client((_) async => http.Response('"ok"', 200));
      await expectLater(client.event(payload: _payload()), completes);
      client.dispose();
    });

    test('retries then gives up without throwing', () async {
      var posts = 0;
      final client = _client(
        (_) async {
          posts += 1;
          return http.Response('nope', 500);
        },
        maxAttempts: 3,
      );

      await client.event(payload: _payload());
      expect(posts, 3);
      client.dispose();
    });

    test('strips trailing slash from base url', () async {
      late Uri posted;
      final client = OpenpanelHttpClient(
        options: const OpenpanelOptions(
          url: 'http://localhost/api/',
          clientId: 'test-client',
        ),
        userAgent: 'test/1.0',
        maxAttempts: 1,
        client: MockClient((request) async {
          posted = request.url;
          return http.Response('{}', 200);
        }),
      );

      await client.event(payload: _payload());
      expect(posted.toString(), 'http://localhost/api/track');
      client.dispose();
    });
  });
}

PostEventPayload _payload() => PostEventPayload(
      name: 'test_event',
      timestamp: DateTime.utc(2026).toIso8601String(),
    );

OpenpanelHttpClient _client(
  Future<http.Response> Function(http.Request request) handler, {
  int maxAttempts = 1,
}) {
  return OpenpanelHttpClient(
    options: const OpenpanelOptions(
      url: 'http://localhost',
      clientId: 'test-client',
      clientSecret: 'test-secret',
    ),
    userAgent: 'test/1.0',
    maxAttempts: maxAttempts,
    client: MockClient(handler),
  );
}
