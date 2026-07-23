import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/models/post_event_payload.dart';
import 'package:openpanel_flutter/src/services/event_queue.dart';
import 'package:openpanel_flutter/src/services/openpanel_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists failed events in delivery order and bounds the queue',
    () async {
      SharedPreferences.setMockInitialValues({});
      final queue = EventQueue(
        SharedPreferencesOpenpanelStorage(
          await SharedPreferences.getInstance(),
        ),
        maximumSize: 2,
        storageKey: 'test:openpanel:pending_events_v1',
      );

      await queue.enqueue(_event('first'));
      await queue.enqueue(_event('second'));
      await queue.enqueue(_event('third'));

      expect((await queue.read()).map((event) => event.name), [
        'second',
        'third',
      ]);
    },
  );

  test('replaces the persisted queue after a successful flush', () async {
    SharedPreferences.setMockInitialValues({});
    final queue = EventQueue(
      SharedPreferencesOpenpanelStorage(await SharedPreferences.getInstance()),
      storageKey: 'test:openpanel:pending_events_v1',
    );
    await queue.enqueue(_event('first'));
    await queue.enqueue(_event('second'));

    await queue.replace([_event('second')]);

    expect((await queue.read()).single.name, 'second');
  });

  test('uses the configured storage key', () async {
    final storage = _MemoryStorage();
    final queue = EventQueue(storage, storageKey: 'custom_pending_events');

    await queue.enqueue(_event('first'));

    expect(storage.values, contains('custom_pending_events'));
  });
}

PostEventPayload _event(String name) => PostEventPayload(
  name: name,
  timestamp: DateTime.utc(2026).toIso8601String(),
);

final class _MemoryStorage implements OpenpanelStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
