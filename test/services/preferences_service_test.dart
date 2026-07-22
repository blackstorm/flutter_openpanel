import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/models/open_panel_state.dart';
import 'package:openpanel_flutter/src/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trips OpenpanelState', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());

    const state = OpenpanelState(
      deviceId: 'device',
      profileId: 'profile',
      properties: {'appVersion': '1.0.0'},
      isTracingSampled: true,
    );

    await prefs.persistState(state);
    final loaded = prefs.getSavedState();

    expect(loaded?.deviceId, 'device');
    expect(loaded?.profileId, 'profile');
    expect(loaded?.properties['appVersion'], '1.0.0');
    expect(loaded?.isTracingSampled, isTrue);
  });
}
