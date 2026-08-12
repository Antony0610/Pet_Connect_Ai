import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// Centralized navigation guard logic for GoRouter.
///
/// NOTE: This is client-side navigation protection for UX purposes ONLY.
/// Database security is strictly enforced at the PostgreSQL layer via RLS.
class RouteGuard {
  const RouteGuard(this._ref);

  final Ref _ref;

  /// Returns a path string to redirect to, or `null` to proceed.
  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;

    // Check current session from initialized Supabase client
    final client = _ref.read(supabaseClientProvider);
    final session = client.auth.currentSession;
    final isAuthenticated = session != null;

    final isSplash = location == RoutePaths.splash;
    final isOnboarding = location == RoutePaths.onboarding;
    final isAuthRoute = location == RoutePaths.login ||
        location == RoutePaths.register ||
        location == RoutePaths.forgotPassword ||
        location == RoutePaths.roleSelection ||
        location == RoutePaths.otpVerification;

    // Splash screen handles its own deferred navigation
    if (isSplash) return null;

    // 1. Unauthenticated user accessing protected portal route → redirect to Login
    if (!isAuthenticated) {
      if (isAuthRoute || isOnboarding) {
        return null; // Proceed to public auth/onboarding screen
      }
      return RoutePaths.login;
    }

    // 2. Authenticated user accessing auth or onboarding screens → redirect to portal home
    if (isAuthRoute || isOnboarding) {
      final user = session.user;
      final roleStr = user.userMetadata?['role'] as String?;
      final portal = AppPortalExtension.fromDbRole(roleStr);
      return portalHome(portal);
    }

    return null;
  }

  /// Maps an [AppPortal] role to its canonical home route.
  static String portalHome(AppPortal portal) => switch (portal) {
        AppPortal.petOwner => RoutePaths.ownerHome,
        AppPortal.veterinarian => RoutePaths.vetHome,
        AppPortal.volunteerRescue => RoutePaths.rescueHome,
        AppPortal.administrator => RoutePaths.adminHome,
      };
}
