import 'package:flutter/widgets.dart';
import 'package:openpanel_flutter/openpanel_flutter.dart';
import 'package:openpanel_flutter/src/models/typedefs.dart';

bool defaultRouteFilter(Route<dynamic>? route) => route is PageRoute;

String? defaultNameExtractor(RouteSettings settings) => settings.name;

/// Tracks `screen_view` for navigator routes.
class OpenpanelObserver extends RouteObserver<ModalRoute<dynamic>> {
  OpenpanelObserver({
    this.routeFilter = defaultRouteFilter,
    this.screenNameExtractor = defaultNameExtractor,
  });

  final RouteFilter routeFilter;
  final ScreenNameExtractor screenNameExtractor;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (routeFilter(route)) _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && routeFilter(newRoute)) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null &&
        routeFilter(previousRoute) &&
        routeFilter(route)) {
      _track(previousRoute);
    }
  }

  void _track(Route<dynamic> route) {
    final name = screenNameExtractor(route.settings);
    if (name == null) return;
    Openpanel.instance.event(name: 'screen_view', properties: {'__path': name});
  }
}
