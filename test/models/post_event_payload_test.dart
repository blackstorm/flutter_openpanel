import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/models/post_event_payload.dart';

void main() {
  test('omits null profileId and deviceId from JSON', () {
    final json = PostEventPayload(
      name: 'screen_view',
      timestamp: '2026-07-23T00:00:00.000Z',
      properties: const {'os': 'iOS'},
    ).toJson();

    expect(json.containsKey('profileId'), isFalse);
    expect(json.containsKey('deviceId'), isFalse);
    expect(json['name'], 'screen_view');
    expect(json['properties'], {'os': 'iOS'});
  });

  test('includes profileId when identified', () {
    final json = PostEventPayload(
      name: 'screen_view',
      timestamp: '2026-07-23T00:00:00.000Z',
      deviceId: 'device-1',
      profileId: 'user-1',
    ).toJson();

    expect(json['deviceId'], 'device-1');
    expect(json['profileId'], 'user-1');
  });
}
