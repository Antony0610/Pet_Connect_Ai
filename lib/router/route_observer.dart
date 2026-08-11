import 'package:flutter/widgets.dart';

import 'package:petconnect_ai/core/utils/logger.dart';

/// Logs route changes for debugging / analytics.
///
/// Attached to the router in `app_router.dart`. In production this is where
/// screen-view analytics events would be dispatched.
class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver(this._logger);

  final AppLogger _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.trace('→ push ${route.settings.name ?? route.settings}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.trace('← pop ${route.settings.name ?? route.settings}');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logger.trace('↔ replace ${newRoute?.settings.name ?? newRoute?.settings}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
