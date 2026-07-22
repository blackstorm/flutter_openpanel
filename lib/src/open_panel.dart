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

    if (saved != null) {
      _state = saved;
    } else {
      final rate = options.tracingSampleRate;
      final sampled = rate >= 1.0 || Random().nextDouble() < rate;
      _state = OpenpanelState(
        profileId: newUuidV4(),
        deviceId: device.properties['deviceId'] as String? ?? newUuidV4(),
        properties: Map<String, dynamic>.from(device.properties),
        isTracingSampled: sampled,
      );
      await _preferences.persistState(_state);
    }

    _http = OpenpanelHttpClient(
      options: options,
      userAgent: device.userAgent,
    );

    WidgetsBinding.instance.addObserver(ReferrerObserver());
    _ready = true;
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

  Future<void> clear() async {
    _state = const OpenpanelState();
    await _preferences.persistState(_state);
  }

  void updateProfile({required UpdateProfilePayload payload}) {
    _run(() {
      setProfileId(payload.profileId);
      _http.updateProfile(
        payload: payload,
        stateProperties: _state.properties,
      );
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
