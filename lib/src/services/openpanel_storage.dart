import 'package:shared_preferences/shared_preferences.dart';

/// Persists OpenPanel data between app launches.
///
/// Supply an implementation to [Openpanel.initialize] to use a storage backend
/// other than [SharedPreferencesOpenpanelStorage].
abstract interface class OpenpanelStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

/// The default [OpenpanelStorage], backed by `shared_preferences`.
final class SharedPreferencesOpenpanelStorage implements OpenpanelStorage {
  SharedPreferencesOpenpanelStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesOpenpanelStorage> create() async {
    return SharedPreferencesOpenpanelStorage(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<String?> readString(String key) async => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }
}
