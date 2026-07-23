import 'dart:convert';

import 'package:openpanel_flutter/src/models/open_panel_state.dart';
import 'package:openpanel_flutter/src/services/openpanel_storage.dart';

/// Serializes the SDK state using the configured [OpenpanelStorage].
final class PreferencesService {
  PreferencesService(this._storage, {required this.storageKey});

  final OpenpanelStorage _storage;
  final String storageKey;

  Future<void> persistState(OpenpanelState state) {
    return _storage.writeString(storageKey, jsonEncode(state.toJson()));
  }

  Future<OpenpanelState?> getSavedState() async {
    final raw = await _storage.readString(storageKey);
    if (raw == null) return null;
    return OpenpanelState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
