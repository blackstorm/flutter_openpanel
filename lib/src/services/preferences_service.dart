import 'dart:convert';

import 'package:openpanel_flutter/src/models/open_panel_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'openpanel_state';

  Future<void> persistState(OpenpanelState state) {
    return _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  OpenpanelState? getSavedState() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return OpenpanelState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
