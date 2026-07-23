import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/models/update_profile_payload.dart';

void main() {
  test('UID-only identify omits PII keys and empty properties', () {
    final json = const UpdateProfilePayload(profileId: 'user-1').toJson();

    expect(json, {'profileId': 'user-1'});
  });
}
