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
import '../features/pet_owner/presentation/screens/add_pet_screen.dart';
import '../features/pet_owner/presentation/screens/ai_assistant_chat_screen.dart';
import '../features/pet_owner/presentation/screens/ai_health_insights_screen.dart';
import '../features/pet_owner/presentation/screens/ai_history_screen.dart';
import '../features/pet_owner/presentation/screens/ai_hub_dashboard_screen.dart';
import '../features/pet_owner/presentation/screens/ai_recommendations_screen.dart';
import '../features/pet_owner/presentation/screens/ai_reports_screen.dart';
import '../features/pet_owner/presentation/screens/community_events_screen.dart';
import '../features/pet_owner/presentation/screens/community_hub_screen.dart';
import '../features/pet_owner/presentation/screens/community_messages_screen.dart';
import '../features/pet_owner/presentation/screens/community_sightings_screen.dart';
import '../features/pet_owner/presentation/screens/create_post_screen.dart';
import '../features/pet_owner/presentation/screens/delete_pet_confirmation_screen.dart';
import '../features/pet_owner/presentation/screens/discover_feed_screen.dart';
import '../features/pet_owner/presentation/screens/edit_pet_profile_screen.dart';
import '../features/pet_owner/presentation/screens/growth_weight_analytics_screen.dart';
import '../features/pet_owner/presentation/screens/health_passport_dashboard_screen.dart';
import '../features/pet_owner/presentation/screens/health_passport_timeline_screen.dart';
import '../features/pet_owner/presentation/screens/home_dashboard_screen.dart';
import '../features/pet_owner/presentation/screens/local_community_screen.dart';
import '../features/pet_owner/presentation/screens/lost_found_community_screen.dart';
import '../features/pet_owner/presentation/screens/medical_history_record_screen.dart';
import '../features/pet_owner/presentation/screens/my_pets_list_screen.dart';
import '../features/pet_owner/presentation/screens/notifications_screen.dart';
import '../features/pet_owner/presentation/screens/pet_adoption_screen.dart';
import '../features/pet_owner/presentation/screens/pet_media_gallery_screen.dart';
import '../features/pet_owner/presentation/screens/pet_profile_detail_screen.dart';
import '../features/pet_owner/presentation/screens/pet_settings_screen.dart';
import '../features/pet_owner/presentation/screens/profile_screen.dart';
import '../features/pet_owner/presentation/screens/settings_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_activity_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_dashboard_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_diagnostics_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_geofence_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_settings_screen.dart';
import '../features/pet_owner/presentation/screens/smart_collar_tracking_screen.dart';
import '../features/pet_owner/presentation/screens/vaccination_overview_screen.dart';
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
            builder: (context, state) => const NotificationsScreen(),
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
                path: 'add',
                name: RouteNames.ownerPetAdd,
                builder: (context, state) => const AddPetScreen(),
              ),
              GoRoute(
                path: ':petId',
                name: RouteNames.ownerPetDetail,
                builder: (context, state) => const PetProfileDetailScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.ownerPetEdit,
                    builder: (context, state) => const EditPetProfileScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.ownerPetSettings,
                    builder: (context, state) => const PetSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'delete',
                    name: RouteNames.ownerPetDelete,
                    builder: (context, state) =>
                        const DeletePetConfirmationScreen(),
                  ),
                  GoRoute(
                    path: 'gallery',
                    name: RouteNames.ownerPetGallery,
                    builder: (context, state) => const PetMediaGalleryScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'health',
            name: RouteNames.ownerHealth,
            builder: (context, state) => const HealthPassportDashboardScreen(),
            routes: [
              GoRoute(
                path: 'medical',
                name: RouteNames.ownerHealthMedical,
                builder: (context, state) => const MedicalHistoryRecordScreen(),
              ),
              GoRoute(
                path: 'vaccinations',
                name: RouteNames.ownerHealthVaccinations,
                builder: (context, state) => const VaccinationOverviewScreen(),
              ),
              GoRoute(
                path: 'timeline',
                name: RouteNames.ownerHealthTimeline,
                builder: (context, state) =>
                    const HealthPassportTimelineScreen(),
              ),
              GoRoute(
                path: 'growth',
                name: RouteNames.ownerHealthGrowth,
                builder: (context, state) =>
                    const GrowthWeightAnalyticsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'ai',
            name: RouteNames.ownerAiAssistant,
            builder: (context, state) => const AiHubDashboardScreen(),
            routes: [
              GoRoute(
                path: 'chat',
                name: RouteNames.ownerAiChat,
                builder: (context, state) => const AiAssistantChatScreen(),
              ),
              GoRoute(
                path: 'insights',
                name: RouteNames.ownerAiInsights,
                builder: (context, state) => const AiHealthInsightsScreen(),
              ),
              GoRoute(
                path: 'recommendations',
                name: RouteNames.ownerAiRecommendations,
                builder: (context, state) => const AiRecommendationsScreen(),
              ),
              GoRoute(
                path: 'reports',
                name: RouteNames.ownerAiReports,
                builder: (context, state) => const AiReportsScreen(),
              ),
              GoRoute(
                path: 'history',
                name: RouteNames.ownerAiHistory,
                builder: (context, state) => const AiHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'collar',
            name: RouteNames.ownerCollar,
            builder: (context, state) => const SmartCollarDashboardScreen(),
            routes: [
              GoRoute(
                path: 'tracking',
                name: RouteNames.ownerCollarTracking,
                builder: (context, state) => const SmartCollarTrackingScreen(),
              ),
              GoRoute(
                path: 'activity',
                name: RouteNames.ownerCollarActivity,
                builder: (context, state) => const SmartCollarActivityScreen(),
              ),
              GoRoute(
                path: 'geofence',
                name: RouteNames.ownerCollarGeofence,
                builder: (context, state) => const SmartCollarGeofenceScreen(),
              ),
              GoRoute(
                path: 'diagnostics',
                name: RouteNames.ownerCollarDiagnostics,
                builder: (context, state) =>
                    const SmartCollarDiagnosticsScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: RouteNames.ownerCollarSettings,
                builder: (context, state) => const SmartCollarSettingsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'lost-mode',
            name: RouteNames.ownerLostMode,
            builder: (context, state) => const ActivateLostModeScreen(),
          ),
          GoRoute(
            path: 'community',
            name: RouteNames.ownerCommunity,
            builder: (context, state) => const CommunityHubScreen(),
            routes: [
              GoRoute(
                path: 'create-post',
                name: RouteNames.ownerCommunityCreatePost,
                builder: (context, state) => const CreatePostScreen(),
              ),
              GoRoute(
                path: 'discover',
                name: RouteNames.ownerCommunityDiscover,
                builder: (context, state) => const DiscoverFeedScreen(),
              ),
              GoRoute(
                path: 'local',
                name: RouteNames.ownerCommunityLocal,
                builder: (context, state) => const LocalCommunityScreen(),
              ),
              GoRoute(
                path: 'sightings',
                name: RouteNames.ownerCommunitySightings,
                builder: (context, state) => const CommunitySightingsScreen(),
              ),
              GoRoute(
                path: 'lost-found',
                name: RouteNames.ownerCommunityLostFound,
                builder: (context, state) => const LostFoundCommunityScreen(),
              ),
              GoRoute(
                path: 'events',
                name: RouteNames.ownerCommunityEvents,
                builder: (context, state) => const CommunityEventsScreen(),
              ),
              GoRoute(
                path: 'adoption',
                name: RouteNames.ownerCommunityAdoption,
                builder: (context, state) => const PetAdoptionScreen(),
              ),
              GoRoute(
                path: 'messages',
                name: RouteNames.ownerCommunityMessages,
                builder: (context, state) => const CommunityMessagesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: RouteNames.ownerProfile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: RouteNames.ownerSettings,
            builder: (context, state) => const SettingsScreen(),
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
