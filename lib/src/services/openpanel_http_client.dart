import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openpanel_flutter/src/constants/constants.dart';
import 'package:openpanel_flutter/src/models/open_panel_options.dart';
import 'package:openpanel_flutter/src/models/post_event_payload.dart';
import 'package:openpanel_flutter/src/models/update_profile_payload.dart';

/// Thin OpenPanel `/track` client.
///
/// Response bodies are ignored: OpenPanel may return a bare string or JSON
/// (stevenosse/openpanel_flutter#4 / PR #6). Casting to `String` used to crash
/// after a successful track.
class OpenpanelHttpClient {
  OpenpanelHttpClient({
    required OpenpanelOptions options,
    required String userAgent,
    http.Client? client,
    this.maxAttempts = 3,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _verbose = options.verbose,
        _trackUri = _trackUriFor(options.url),
        _headers = {
          'content-type': 'application/json',
          'openpanel-client-id': options.clientId,
          'openpanel-sdk-name': kSdkName,
          'openpanel-sdk-version': kSdkVersion,
          'User-Agent': userAgent,
          if (options.clientSecret != null)
            'openpanel-client-secret': options.clientSecret!,
        };

  final http.Client _client;
  final bool _ownsClient;
  final int maxAttempts;
  final bool _verbose;
  final Uri _trackUri;
  final Map<String, String> _headers;

  static Uri _trackUriFor(String? baseUrl) {
    final root = (baseUrl ?? kDefaultBaseUrl).replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$root/track');
  }

  void updateProfile({
    required UpdateProfilePayload payload,
    required Map<String, dynamic> stateProperties,
  }) {
    unawaited(
      _post({
        'type': 'identify',
        'payload': {
          ...payload.toJson(),
          'properties': {
            ...payload.properties,
            ...stateProperties,
          },
        },
      }),
    );
  }

  void increment({
    required String profileId,
    required String property,
    required int value,
  }) {
    _mutateProperty(
      type: 'increment',
      profileId: profileId,
      property: property,
      value: value,
    );
  }

  void decrement({
    required String profileId,
    required String property,
    required int value,
  }) {
    _mutateProperty(
      type: 'decrement',
      profileId: profileId,
      property: property,
      value: value,
    );
  }

  Future<void> event({required PostEventPayload payload}) {
    return _post({
      'type': 'track',
      'payload': payload.toJson(),
    });
  }

  void _mutateProperty({
    required String type,
    required String profileId,
    required String property,
    required int value,
  }) {
    unawaited(
      _post({
        'type': type,
        'payload': {
          'profileId': profileId,
          'property': property,
          'value': value,
        },
      }),
    );
  }

  Future<void> _post(Map<String, dynamic> body) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await _client
            .post(
              _trackUri,
              headers: _headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    if (_verbose) {
      debugPrint('[openpanel] track failed: $lastError');
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
