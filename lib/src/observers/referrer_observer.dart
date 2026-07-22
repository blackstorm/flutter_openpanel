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
      final referrer = (await r.Referrer().getReferrer())?.referrer;
      if (referrer != null) {
        Openpanel.instance
            .setGlobalProperties({'__referrer': referrer.toString()});
      }
    } catch (_) {
      // Best-effort only.
    }
  }
}
