import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:openpanel_flutter/src/constants/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Single pass over package + device APIs (UA + event properties).
class DeviceContext {
  const DeviceContext({
    required this.userAgent,
    required this.properties,
  });

  final String userAgent;
  final Map<String, dynamic> properties;

  static Future<DeviceContext> collect({
    DeviceInfoPlugin? deviceInfo,
    PackageInfo? packageInfo,
  }) async {
    final package = packageInfo ?? await PackageInfo.fromPlatform();
    final info = deviceInfo ?? DeviceInfoPlugin();

    final properties = <String, dynamic>{
      'appVersion': package.version,
      'buildNumber': package.buildNumber,
      'installerStore': package.installerStore,
    };

    String platformLabel = 'Unknown';
    String model = 'Unknown';

    try {
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        platformLabel = 'Web';
        model = web.browserName.name;
        properties['brand'] = web.browserName.name;
        properties['model'] = web.appVersion;
        properties['osVersion'] = web.platform;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final android = await info.androidInfo;
            platformLabel = 'Android ${android.version.release}';
            model = android.model;
            properties.addAll({
              'deviceId': android.id,
              'brand': android.brand,
              'model': android.model,
              'manufacturer': android.manufacturer,
              'osVersion': android.version.release,
            });
          case TargetPlatform.iOS:
            final ios = await info.iosInfo;
            platformLabel = 'iOS ${ios.systemVersion}';
            // Hardware id (iPhone17,5). Never ios.name (user-visible, may be PII).
            model = ios.utsname.machine;
            properties.addAll({
              'deviceId': ios.identifierForVendor,
              'brand': 'Apple',
              'model': model,
              'osVersion': ios.systemVersion,
            });
          case TargetPlatform.macOS:
            final mac = await info.macOsInfo;
            platformLabel = 'macOS ${mac.osRelease}';
            model = mac.model;
            properties.addAll({
              'deviceId': mac.systemGUID,
              'brand': 'Apple',
              'model': mac.model,
              'osVersion': mac.osRelease,
            });
          case TargetPlatform.windows:
            final windows = await info.windowsInfo;
            platformLabel = 'Windows ${windows.displayVersion}';
            // Avoid computerName / userName — often personal.
            model = 'Windows';
            properties.addAll({
              'deviceId': windows.deviceId,
              'brand': 'Microsoft',
              'model': model,
              'osVersion': windows.displayVersion,
            });
          case TargetPlatform.linux:
            final linux = await info.linuxInfo;
            platformLabel = 'Linux ${linux.version ?? 'Unknown'}';
            model = linux.name;
            properties.addAll({
              'deviceId': linux.machineId,
              'brand': linux.name,
              'model': linux.prettyName,
              'osVersion': linux.version,
            });
          case TargetPlatform.fuchsia:
            break;
        }
      }
    } catch (_) {
      // Keep package fields; UA falls back below.
    }

    final userAgent = buildUserAgent(
      platformLabel: platformLabel,
      model: model,
    );

    return DeviceContext(userAgent: userAgent, properties: properties);
  }

  /// SDK identity for the HTTP `User-Agent` header (ASCII-safe).
  ///
  /// Example: `openpanel-flutter/0.4.0 (iOS 26.3.1; iPhone17,5)`
  @visibleForTesting
  static String buildUserAgent({
    required String platformLabel,
    required String model,
    String sdkName = kSdkName,
    String sdkVersion = kSdkVersion,
  }) {
    final raw =
        '${_asciiHeaderToken(sdkName, fallback: 'openpanel-flutter')}/'
        '${_asciiHeaderToken(sdkVersion, fallback: '0')} '
        '(${_asciiHeaderToken(platformLabel, fallback: 'Unknown')}; '
        '${_asciiHeaderToken(model, fallback: 'Unknown')})';
    return _asciiHeaderToken(raw, fallback: 'openpanel-flutter/0');
  }

  static String _asciiHeaderToken(String raw, {required String fallback}) {
    final cleaned = String.fromCharCodes(
      raw.codeUnits.where((c) => c == 0x09 || (c >= 0x20 && c <= 0x7e)),
    ).trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }
}
