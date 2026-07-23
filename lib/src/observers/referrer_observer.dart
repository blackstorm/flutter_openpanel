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
      final properties = installReferrerProperties(referrer?.toString());
      if (properties.isNotEmpty) {
        Openpanel.instance.setGlobalProperties(properties);
      }
    } catch (_) {
      // Best-effort only.
    }
  }
}

/// Extracts a small acquisition taxonomy without retaining a raw URL.
///
/// Install-referrer strings can contain arbitrary query parameters. Retaining
/// the complete string risks capturing personal or partner-specific tokens;
/// only conventional UTM values with identifier-safe characters are useful to
/// product operations and safe to use as event dimensions.
@visibleForTesting
Map<String, String> installReferrerProperties(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return const <String, String>{};

  try {
    final uri = Uri.tryParse(value);
    final query = uri?.hasQuery == true
        ? uri!.query
        : value.startsWith('?')
        ? value.substring(1)
        : value;
    final params = Uri.splitQueryString(query);
    const acquisitionPropertyByUtmKey = <String, String>{
      'utm_source': 'acquisition_source',
      'utm_medium': 'acquisition_medium',
      'utm_campaign': 'acquisition_campaign',
    };
    final result = <String, String>{};
    for (final mapping in acquisitionPropertyByUtmKey.entries) {
      final item = params[mapping.key]?.trim() ?? '';
      if (_isSafeAcquisitionValue(item)) {
        result[mapping.value] = item;
      }
    }
    return result;
  } catch (_) {
    return const <String, String>{};
  }
}

final _safeAcquisitionValuePattern = RegExp(r'^[A-Za-z0-9._-]+$');

bool _isSafeAcquisitionValue(String value) =>
    value.length <= 64 && _safeAcquisitionValuePattern.hasMatch(value);
