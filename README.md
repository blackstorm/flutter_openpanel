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

```dart
Openpanel.instance.event(name: 'button_clicked', properties: {'id': 'pay'});
```

```dart
MaterialApp(
  navigatorObservers: [OpenpanelObserver()],
);
```
