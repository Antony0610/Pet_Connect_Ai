import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/core_providers.dart';
import '../features/auth/presentation/screens/create_account_screen.dart';
import '../features/auth/presentation/screens/initial_pet_setup_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_success_screen.dart';
import '../features/pet_owner/presentation/screens/activate_lost_mode_screen.dart';
import '../features/pet_owner/presentation/screens/home_dashboard_screen.dart';
import '../features/pet_owner/presentation/screens/my_pets_list_screen.dart';
import '../shared/widgets/placeholder_screen.dart';
import 'route_guard.dart';
import 'route_observer.dart';
import 'route_paths.dart';

/// The app's [GoRouter], exposed via Riverpod.
///
/// FOUNDATION SCOPE: this declares the complete navigation graph for all four
/// portals with every destination pointing at a [PlaceholderScreen]. Feature
/// phases replace the `builder` of their routes with real screens; the paths,
/// names, and structure defined here stay stable.
///
/// Auth redirect logic lives in [RouteGuard] (currently permissive — no
/// gating until the Auth feature phase wires real session state).
final routerProvider = Provider<GoRouter>((ref) {
  final logger = ref.watch(loggerProvider);
  final guard = RouteGuard(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: ref.watch(appConfigProvider).isDebuggable,
    observers: [AppRouteObserver(logger)],
    redirect: guard.redirect,
    errorBuilder: (context, state) => PlaceholderScreen(
      title: 'Not Found',
      subtitle: 'No route for "${state.uri}".',
    ),
    routes: [
      // ── Root / shared ──────────────────────────────────────────
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Forgot Password'),
      ),
      GoRoute(
        path: RoutePaths.roleSelection,
        name: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.otpVerification,
        name: RouteNames.otpVerification,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcomeSuccess,
        name: RouteNames.welcomeSuccess,
        builder: (context, state) => const WelcomeSuccessScreen(),
      ),
      GoRoute(
        path: RoutePaths.initialPetSetup,
        name: RouteNames.initialPetSetup,
        builder: (context, state) => const InitialPetSetupScreen(),
      ),

      // ── Pet Owner portal ───────────────────────────────────────
      GoRoute(
        path: RoutePaths.ownerHome,
        name: RouteNames.ownerHome,
        builder: (context, state) => const HomeDashboardScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            name: RouteNames.ownerNotifications,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Notifications'),
          ),
          GoRoute(
            path: 'search',
            name: RouteNames.ownerSearch,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Search'),
          ),
          GoRoute(
            path: 'pets',
            name: RouteNames.ownerPets,
            builder: (context, state) => const MyPetsListScreen(),
            routes: [
              GoRoute(
                path: ':petId',
                name: RouteNames.ownerPetDetail,
                builder: (context, state) => PlaceholderScreen(
                  title: 'Pet Detail',
                  subtitle: 'petId: ${state.pathParameters['petId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'health',
            name: RouteNames.ownerHealth,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Health'),
          ),
          GoRoute(
            path: 'ai',
            name: RouteNames.ownerAiAssistant,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'AI Assistant'),
          ),
          GoRoute(
            path: 'collar',
            name: RouteNames.ownerCollar,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Smart Collar'),
          ),
          GoRoute(
            path: 'lost-mode',
            name: RouteNames.ownerLostMode,
            builder: (context, state) => const ActivateLostModeScreen(),
          ),
          GoRoute(
            path: 'community',
            name: RouteNames.ownerCommunity,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Community'),
          ),
          GoRoute(
            path: 'profile',
            name: RouteNames.ownerProfile,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Profile'),
          ),
          GoRoute(
            path: 'settings',
            name: RouteNames.ownerSettings,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Settings'),
          ),
        ],
      ),

      // ── Veterinarian portal ────────────────────────────────────
      GoRoute(
        path: RoutePaths.vetHome,
        name: RouteNames.vetHome,
        builder: (context, state) => const PlaceholderScreen(title: 'Vet Home'),
        routes: [
          GoRoute(
            path: 'appointments',
            name: RouteNames.vetAppointments,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Appointments'),
          ),
          GoRoute(
            path: 'patients',
            name: RouteNames.vetPatients,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Patients'),
            routes: [
              GoRoute(
                path: ':patientId',
                name: RouteNames.vetPatientDetail,
                builder: (context, state) => PlaceholderScreen(
                  title: 'Patient Detail',
                  subtitle: 'patientId: ${state.pathParameters['patientId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: RouteNames.vetProfile,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Vet Profile'),
          ),
        ],
      ),

      // ── Volunteer & Rescue portal ──────────────────────────────
      GoRoute(
        path: RoutePaths.rescueHome,
        name: RouteNames.rescueHome,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Rescue Home'),
        routes: [
          GoRoute(
            path: 'cases',
            name: RouteNames.rescueCases,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Rescue Cases'),
            routes: [
              GoRoute(
                path: ':caseId',
                name: RouteNames.rescueCaseDetail,
                builder: (context, state) => PlaceholderScreen(
                  title: 'Case Detail',
                  subtitle: 'caseId: ${state.pathParameters['caseId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'map',
            name: RouteNames.rescueMap,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Rescue Map'),
          ),
          GoRoute(
            path: 'profile',
            name: RouteNames.rescueProfile,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Rescue Profile'),
          ),
        ],
      ),

      // ── Administrator portal ───────────────────────────────────
      GoRoute(
        path: RoutePaths.adminHome,
        name: RouteNames.adminHome,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Admin Home'),
        routes: [
          GoRoute(
            path: 'users',
            name: RouteNames.adminUsers,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'User Management'),
          ),
          GoRoute(
            path: 'moderation',
            name: RouteNames.adminModeration,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Moderation'),
          ),
          GoRoute(
            path: 'analytics',
            name: RouteNames.adminAnalytics,
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Analytics'),
          ),
        ],
      ),
    ],
  );
});
