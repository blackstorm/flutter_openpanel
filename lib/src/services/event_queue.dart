import 'dart:convert';

import 'package:openpanel_flutter/src/models/post_event_payload.dart';
import 'package:openpanel_flutter/src/services/openpanel_storage.dart';

/// A small persistent queue for events that could not reach `/track`.
///
/// Delivery is intentionally at-least-once. Consumers can use the payload
/// timestamp together with product dimensions when investigating a rare retry
/// duplicate; dropping first-session events is considerably more harmful to a
/// funnel than that conservative trade-off.
final class EventQueue {
  EventQueue(this._storage, {this.maximumSize = 250, required this.storageKey});

  final OpenpanelStorage _storage;
  final int maximumSize;
  final String storageKey;

  Future<List<PostEventPayload>> read() async {
    final raw = await _storage.readString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                PostEventPayload.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      // A malformed legacy entry must never prevent new analytics delivery.
      return const [];
    }
  }

  Future<void> enqueue(PostEventPayload payload) async {
    final events = [...await read(), payload];
    final start = events.length > maximumSize ? events.length - maximumSize : 0;
    await replace(events.sublist(start));
  }

  Future<void> replace(List<PostEventPayload> events) {
    return _storage.writeString(
      storageKey,
      jsonEncode(events.map((event) => event.toJson()).toList(growable: false)),
    );
  }
}
