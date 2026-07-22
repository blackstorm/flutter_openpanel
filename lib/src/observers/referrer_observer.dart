import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:openpanel_flutter/openpanel_flutter.dart';
import 'package:referrer/referrer.dart' as r;

/// Captures install referrer once (Android / iOS).
class ReferrerObserver with WidgetsBindingObserver {
  static bool _loaded = false;

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    await _loadOnce();
    return super.didPushRouteInformation(routeInformation);
  }

  static Future<void> _loadOnce() async {
    if (_loaded) return;
    _loaded = true;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      final info = await r.Referrer().getReferrer();
      final value = info?.referrer;
      if (value != null) {
        Openpanel.instance.setGlobalProperties({'__referrer': value.toString()});
      }
    } catch (_) {
      // Referrer is best-effort.
    }
  }
}
