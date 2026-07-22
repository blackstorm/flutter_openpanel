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
      final client = MockClient((request) async {
        posts += 1;
        expect(request.url.path, endsWith('/track'));
        expect(jsonDecode(request.body), isA<Map<String, dynamic>>());
        return http.Response(
          '{"deviceId":"d1","sessionId":"s1"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final httpClient = OpenpanelHttpClient(client: client, maxAttempts: 1);
      httpClient.init(
        options: const OpenpanelOptions(
          url: 'http://localhost',
          clientId: 'test-client',
          clientSecret: 'test-secret',
        ),
        userAgent: 'test/1.0',
      );

      await httpClient.event(
        payload: PostEventPayload(
          name: 'test_event',
          timestamp: DateTime.utc(2026).toIso8601String(),
        ),
      );

      expect(posts, 1);
      httpClient.dispose();
    });

    test('accepts a plain string response body', () async {
      final client = MockClient(
        (_) async => http.Response('"ok"', 200),
      );
      final httpClient = OpenpanelHttpClient(client: client, maxAttempts: 1);
      httpClient.init(
        options: const OpenpanelOptions(
          url: 'http://localhost',
          clientId: 'test-client',
        ),
        userAgent: 'test/1.0',
      );

      await expectLater(
        httpClient.event(
          payload: PostEventPayload(
            name: 'test_event',
            timestamp: DateTime.utc(2026).toIso8601String(),
          ),
        ),
        completes,
      );
      httpClient.dispose();
    });

    test('retries then gives up without throwing', () async {
      var posts = 0;
      final client = MockClient((_) async {
        posts += 1;
        return http.Response('nope', 500);
      });
      final httpClient = OpenpanelHttpClient(client: client, maxAttempts: 3);
      httpClient.init(
        options: const OpenpanelOptions(
          url: 'http://localhost',
          clientId: 'test-client',
        ),
        userAgent: 'test/1.0',
      );

      await httpClient.event(
        payload: PostEventPayload(
          name: 'test_event',
          timestamp: DateTime.utc(2026).toIso8601String(),
        ),
      );
      expect(posts, 3);
      httpClient.dispose();
    });
  });
}
