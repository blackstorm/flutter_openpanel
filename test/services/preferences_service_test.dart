import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/openpanel_flutter.dart';
import 'package:openpanel_flutter/src/models/open_panel_state.dart';
import 'package:openpanel_flutter/src/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trips OpenpanelState', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(
      SharedPreferencesOpenpanelStorage(await SharedPreferences.getInstance()),
      storageKey: 'test:openpanel:state',
    );

    const state = OpenpanelState(
      deviceId: 'device',
      profileId: 'profile',
      properties: {'appVersion': '1.0.0'},
      isTracingSampled: true,
    );

    await prefs.persistState(state);
    final loaded = await prefs.getSavedState();

    expect(loaded?.deviceId, 'device');
    expect(loaded?.profileId, 'profile');
    expect(loaded?.properties['appVersion'], '1.0.0');
    expect(loaded?.isTracingSampled, isTrue);
  });

  test('supports a custom storage backend and key', () async {
    final storage = _MemoryStorage();
    final prefs = PreferencesService(storage, storageKey: 'custom_state');
    const state = OpenpanelState(deviceId: 'device');

    await prefs.persistState(state);

    expect((await prefs.getSavedState())?.deviceId, state.deviceId);
    expect(storage.values, contains('custom_state'));
  });
}

final class _MemoryStorage implements OpenpanelStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
