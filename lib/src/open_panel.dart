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
import 'package:openpanel_flutter/src/services/event_queue.dart';
import 'package:openpanel_flutter/src/services/openpanel_http_client.dart';
import 'package:openpanel_flutter/src/services/openpanel_storage.dart';
import 'package:openpanel_flutter/src/services/preferences_service.dart';
import 'package:openpanel_flutter/src/utils/uuid.dart';

class Openpanel {
  Openpanel._();

  /// The default namespace for all SDK-owned storage keys.
  static const defaultStorageKeyPrefix = 'openpanel';
  static const _stateStorageKeySuffix = 'state';
  static const _pendingEventsStorageKeySuffix = 'pending_events_v1';

  static final Openpanel instance = Openpanel._();

  factory Openpanel() => instance;

  late final OpenpanelOptions options;
  late final OpenpanelStorage _storage;
  late final PreferencesService _preferences;
  late final OpenpanelHttpClient _http;
  late final EventQueue _eventQueue;

  bool _ready = false;
  OpenpanelState _state = const OpenpanelState();
  Future<void> _deliveryTail = Future<void>.value();

  /// Initializes OpenPanel with [storage], or SharedPreferences by default.
  ///
  /// [storageKeyPrefix] namespaces persisted SDK state and pending events.
  /// Keys use Redis-style colon separators and default to the `openpanel`
  /// namespace.
  Future<void> initialize({
    required OpenpanelOptions options,
    OpenpanelStorage? storage,
    String storageKeyPrefix = defaultStorageKeyPrefix,
  }) async {
    if (_ready) return;
    this.options = options;

    _storage = storage ?? await SharedPreferencesOpenpanelStorage.create();
    _preferences = PreferencesService(
      _storage,
      storageKey: _storageKey(storageKeyPrefix, _stateStorageKeySuffix),
    );
    final saved = await _preferences.getSavedState();
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

    _http = OpenpanelHttpClient(options: options, userAgent: device.userAgent);
    _eventQueue = EventQueue(
      _storage,
      storageKey: _storageKey(storageKeyPrefix, _pendingEventsStorageKeySuffix),
    );

    WidgetsBinding.instance.addObserver(ReferrerObserver());
    _ready = true;
    unawaited(_enqueueDelivery(() async => _flushPendingEvents()));
  }

  static String _storageKey(String prefix, String suffix) => '$prefix:$suffix';

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
    final reusesPseudonymousDeviceId =
        !saved.deviceIdIsHardware &&
        savedDeviceId != null &&
        savedDeviceId.isNotEmpty;
    final savedProperties = Map<String, dynamic>.from(saved.properties)
      // These keys were produced by older SDK builds. Do not keep forwarding a
      // hardware identifier or an opaque install-referrer URL after upgrade.
      ..remove('deviceId')
      ..remove('__referrer');
    return OpenpanelState(
      deviceId: reusesPseudonymousDeviceId ? savedDeviceId : fallbackDeviceId,
      deviceIdIsHardware: false,
      properties: savedProperties.isNotEmpty
          ? savedProperties
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
    _mutate(_state.copyWith(properties: {..._state.properties, ...properties}));
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
      final profileId = properties['profileId'] as String? ?? _state.profileId;
      final eventProperties = Map<String, dynamic>.from(properties)
        ..remove('profileId');

      unawaited(
        _enqueueDelivery(
          () => _deliver(
            PostEventPayload(
              name: name,
              timestamp: DateTime.timestamp().toIso8601String(),
              deviceId: _state.deviceId,
              profileId: profileId,
              properties: {..._state.properties, ...eventProperties},
            ),
          ),
        ),
      );
    });
  }

  Future<void> _enqueueDelivery(Future<void> Function() operation) {
    _deliveryTail = _deliveryTail.then((_) => operation()).catchError((
      error,
      stack,
    ) {
      if (options.verbose) {
        debugPrint('[openpanel] queued delivery failed: $error\n$stack');
      }
    });
    return _deliveryTail;
  }

  Future<void> _deliver(PostEventPayload payload) async {
    if (!await _flushPendingEvents()) {
      await _eventQueue.enqueue(payload);
      return;
    }
    if (!await _http.event(payload: payload)) {
      await _eventQueue.enqueue(payload);
    }
  }

  Future<bool> _flushPendingEvents() async {
    final pending = await _eventQueue.read();
    for (var index = 0; index < pending.length; index++) {
      if (!await _http.event(payload: pending[index])) return false;
      await _eventQueue.replace(pending.sublist(index + 1));
    }
    return true;
  }

  void _adjustProperty({
    required String property,
    required int value,
    required OpenpanelEventOptions? eventOptions,
    required void Function({
      required String profileId,
      required String property,
      required int value,
    })
    send,
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
