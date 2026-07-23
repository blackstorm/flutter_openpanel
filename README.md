# openpanel_flutter (fork)

Unofficial Flutter SDK for [Openpanel](https://openpanel.dev).

Maintained fork: https://github.com/blackstorm/flutter_openpanel  
Upstream: https://github.com/stevenosse/openpanel_flutter

## Install

```yaml
dependencies:
  openpanel_flutter:
    git:
      url: https://github.com/blackstorm/flutter_openpanel.git
      ref: main
```

## Usage

```dart
import 'package:openpanel_flutter/openpanel_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Openpanel.instance.initialize(
    options: OpenpanelOptions(
      clientId: '<CLIENT_ID>',
      clientSecret: '<CLIENT_SECRET>', // optional
      url: 'https://api.openpanel.dev', // optional / self-host
    ),
  );
  runApp(const MyApp());
}
```

### Custom storage

OpenPanel uses `shared_preferences` by default. To use another backend, provide
an `OpenpanelStorage` implementation when initializing the SDK:

```dart
final storage = MyOpenpanelStorage();

await Openpanel.instance.initialize(
  options: OpenpanelOptions(clientId: '<CLIENT_ID>'),
  storage: storage,
  storageKeyPrefix: 'my_app:openpanel', // optional
);
```

`OpenpanelStorage` is a string key-value interface. The SDK uses it for its
state and for its pending-event queue, so an implementation can use platform
secure storage, a database, or an in-memory store. `storageKeyPrefix` is a
Redis-style namespace: the default produces `openpanel:state` and
`openpanel:pending_events_v1`; `my_app:openpanel` produces
`my_app:openpanel:state` and `my_app:openpanel:pending_events_v1`.

```dart
Openpanel.instance.event(name: 'button_clicked', properties: {'id': 'pay'});
```

```dart
MaterialApp(
  navigatorObservers: [OpenpanelObserver()],
);
```
