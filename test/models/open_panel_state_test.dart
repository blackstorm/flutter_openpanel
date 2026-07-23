import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/models/open_panel_state.dart';

void main() {
  test('copyWith can clear profileId', () {
    const state = OpenpanelState(
      deviceId: 'device-1',
      profileId: 'user-1',
    );

    final cleared = state.copyWith(clearProfileId: true);

    expect(cleared.deviceId, 'device-1');
    expect(cleared.profileId, isNull);
  });
}
