import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Centralized navigation guard / redirect logic.
///
/// FOUNDATION SCOPE: intentionally **permissive** — it performs no gating yet
/// and returns `null` (no redirect) for every location. The structure is in
/// place so the Auth feature phase can implement session- and role-based
/// routing here (e.g. redirect unauthenticated users to `/login`, route each
/// role to its portal home) **without touching `app_router.dart`**.
class RouteGuard {
  const RouteGuard(this._ref);

  // Kept for when auth/session providers are read during redirect.
  // ignore: unused_field
  final Ref _ref;

  /// GoRouter redirect callback. Returns a path to redirect to, or `null` to
  /// proceed to the requested location.
  String? redirect(BuildContext context, GoRouterState state) {
    // TODO(auth): once the Auth feature lands, read session + role here and:
    //   - send unauthenticated users from protected routes to RoutePaths.login
    //   - send authenticated users away from auth routes to their portal home
    //   - enforce per-portal role access
    return null;
  }
}
