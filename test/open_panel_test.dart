import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/openpanel_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses storageKeyPrefix for persisted SDK state', () async {
    PackageInfo.setMockInitialValues(
      appName: 'OpenPanel test',
      packageName: 'dev.openpanel.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final storage = _MemoryStorage();

    await Openpanel.instance.initialize(
      options: const OpenpanelOptions(clientId: 'client'),
      storage: storage,
      storageKeyPrefix: 'test:openpanel',
    );

    expect(storage.values, contains('test:openpanel:state'));
  });
}

final class _MemoryStorage implements OpenpanelStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
