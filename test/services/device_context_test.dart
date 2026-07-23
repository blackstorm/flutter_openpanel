import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/constants/constants.dart';
import 'package:openpanel_flutter/src/services/device_context.dart';

void main() {
  group('DeviceContext.buildUserAgent', () {
    test('uses openpanel-flutter sdk name and version', () {
      final ua = DeviceContext.buildUserAgent(
        platformLabel: 'iOS 26.3.1',
        model: 'iPhone17,5',
      );

      expect(
        ua,
        '$kSdkName/$kSdkVersion (iOS 26.3.1; iPhone17,5)',
      );
      expect(ua.startsWith('openpanel-flutter/'), isTrue);
      expect(ua.codeUnits.every((c) => c == 0x09 || (c >= 0x20 && c <= 0x7e)), isTrue);
    });

    test('strips non-ASCII from platform bits', () {
      final ua = DeviceContext.buildUserAgent(
        platformLabel: 'iOS 中文',
        model: '设备',
      );

      expect(ua, '$kSdkName/$kSdkVersion (iOS; Unknown)');
    });
  });
}
