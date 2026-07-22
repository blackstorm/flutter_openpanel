import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
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
            model = ios.utsname.machine;
            properties.addAll({
              'deviceId': ios.identifierForVendor,
              'brand': ios.name,
              'model': ios.model,
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
            model = windows.computerName;
            properties.addAll({
              'deviceId': windows.deviceId,
              'brand': 'Microsoft',
              'model': windows.computerName,
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

    final userAgent =
        '${package.appName}/${package.version} ($platformLabel; $model; build:${package.buildNumber})';

    return DeviceContext(userAgent: userAgent, properties: properties);
  }
}
