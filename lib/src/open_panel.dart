import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:openpanel_flutter/src/models/open_panel_event_options.dart';
import 'package:openpanel_flutter/src/models/open_panel_options.dart';
import 'package:openpanel_flutter/src/models/open_panel_state.dart';
import 'package:openpanel_flutter/src/models/post_event_payload.dart';
import 'package:openpanel_flutter/src/models/update_profile_payload.dart';
import 'package:openpanel_flutter/src/observers/referrer_observer.dart';
import 'package:openpanel_flutter/src/services/device_context.dart';
import 'package:openpanel_flutter/src/services/openpanel_http_client.dart';
import 'package:openpanel_flutter/src/services/preferences_service.dart';
import 'package:openpanel_flutter/src/utils/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Openpanel {
  Openpanel._();

  static final Openpanel instance = Openpanel._();

  factory Openpanel() => instance;

  late final OpenpanelOptions options;
  late final PreferencesService _preferences;
  late final OpenpanelHttpClient _http;

  bool _ready = false;
  OpenpanelState _state = const OpenpanelState();

  Future<void> initialize({required OpenpanelOptions options}) async {
    if (_ready) return;
    this.options = options;

    _preferences = PreferencesService(await SharedPreferences.getInstance());
    final saved = _preferences.getSavedState();
    final device = await DeviceContext.collect();
    final fallbackDeviceId =
        device.properties['deviceId'] as String? ?? newUuidV4();
    final deviceProperties = Map<String, dynamic>.from(device.properties);

    _state = _restoreState(
      saved: saved,
      fallbackDeviceId: fallbackDeviceId,
      deviceProperties: deviceProperties,
      tracingSampleRate: options.tracingSampleRate,
    );
    await _preferences.persistState(_state);

    _http = OpenpanelHttpClient(
      options: options,
      userAgent: device.userAgent,
    );

    WidgetsBinding.instance.addObserver(ReferrerObserver());
    _ready = true;
  }

  /// Restores device continuity; never restores [OpenpanelState.profileId].
  ///
  /// A stale anonymous profileId (≠ deviceId) makes OpenPanel UI show
  /// "Unknown". The app rebinds identity via [identify] after session load.
  static OpenpanelState _restoreState({
    required OpenpanelState? saved,
    required String fallbackDeviceId,
    required Map<String, dynamic> deviceProperties,
    required double tracingSampleRate,
  }) {
    if (saved == null) {
      final sampled =
          tracingSampleRate >= 1.0 || Random().nextDouble() < tracingSampleRate;
      return OpenpanelState(
        deviceId: fallbackDeviceId,
        properties: deviceProperties,
        isTracingSampled: sampled,
      );
    }

    final savedDeviceId = saved.deviceId?.trim();
    return OpenpanelState(
      deviceId: (savedDeviceId != null && savedDeviceId.isNotEmpty)
          ? savedDeviceId
          : fallbackDeviceId,
      properties: saved.properties.isNotEmpty
          ? Map<String, dynamic>.from(saved.properties)
          : deviceProperties,
      isCollectionEnabled: saved.isCollectionEnabled,
      isTracingSampled: saved.isTracingSampled,
    );
  }

  void setCollectionEnabled(bool enabled) {
    _mutate(_state.copyWith(isCollectionEnabled: enabled));
  }

  void setProfileId(String profileId) {
    _mutate(_state.copyWith(profileId: profileId));
  }

  void setGlobalProperties(Map<String, dynamic> properties) {
    _mutate(
      _state.copyWith(properties: {
        ..._state.properties,
        ...properties,
      }),
    );
  }

  /// Clears identified user; keeps [deviceId] so later events stay anonymous.
  Future<void> clear() async {
    _state = _state.copyWith(clearProfileId: true);
    await _preferences.persistState(_state);
  }

  /// Bind events to an internal user id (OpenPanel `identify`).
  void identify(String profileId) {
    updateProfile(payload: UpdateProfilePayload(profileId: profileId));
  }

  void updateProfile({required UpdateProfilePayload payload}) {
    _run(() {
      setProfileId(payload.profileId);
      _http.updateProfile(payload: payload);
    });
  }

  void increment({
    required String property,
    required int value,
    OpenpanelEventOptions? eventOptions,
  }) {
    _adjustProperty(
      property: property,
      value: value,
      eventOptions: eventOptions,
      send: _http.increment,
    );
  }

  void decrement({
    required String property,
    required int value,
    OpenpanelEventOptions? eventOptions,
  }) {
    _adjustProperty(
      property: property,
      value: value,
      eventOptions: eventOptions,
      send: _http.decrement,
    );
  }

  void event({
    required String name,
    Map<String, dynamic> properties = const {},
  }) {
    _run(() {
      final profileId =
          properties['profileId'] as String? ?? _state.profileId;
      final eventProperties = Map<String, dynamic>.from(properties)
        ..remove('profileId');

      unawaited(
        _track(
          PostEventPayload(
            name: name,
            timestamp: DateTime.timestamp().toIso8601String(),
            deviceId: _state.deviceId,
            profileId: profileId,
            properties: {
              ..._state.properties,
              ...eventProperties,
            },
          ),
        ),
      );
    });
  }

  Future<void> _track(PostEventPayload payload) async {
    try {
      await _http.event(payload: payload);
    } catch (error, stack) {
      if (options.verbose) {
        debugPrint('[openpanel] track failed: $error\n$stack');
      }
    }
  }

  void _adjustProperty({
    required String property,
    required int value,
    required OpenpanelEventOptions? eventOptions,
    required void Function({
      required String profileId,
      required String property,
      required int value,
    }) send,
  }) {
    _run(() {
      final profileId = eventOptions?.profileId ?? _state.profileId;
      if (profileId == null) return;
      send(profileId: profileId, property: property, value: value);
    });
  }

  void _run(void Function() action) {
    if (!_ready) {
      throw StateError(
        'Openpanel is not initialised. Call Openpanel.instance.initialize first.',
      );
    }
    if (!_state.isCollectionEnabled || !_state.isTracingSampled) return;
    action();
  }

  void _mutate(OpenpanelState next) {
    _state = next;
    unawaited(_preferences.persistState(_state));
  }
}
