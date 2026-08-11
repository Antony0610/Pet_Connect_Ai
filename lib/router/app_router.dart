import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/create_account_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/initial_pet_setup_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:petconnect_ai/features/auth/presentation/screens/welcome_success_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/activate_lost_mode_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/add_pet_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_assistant_chat_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_diagnostic_center_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_health_analysis_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_health_insights_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_history_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_hub_dashboard_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_recommendations_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_reports_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/ai_scan_identify_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_achievements_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_events_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_hub_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_messages_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_search_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/community_sightings_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/create_post_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/delete_pet_confirmation_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/discover_feed_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/edit_pet_profile_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/global_search_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/growth_weight_analytics_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/health_passport_dashboard_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/health_passport_timeline_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/home_dashboard_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/live_activity_feed_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/local_community_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/lost_found_community_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/lost_pet_dashboard_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/medical_history_record_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/my_pets_list_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/notifications_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_adoption_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_documents_vault_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_media_gallery_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_profile_detail_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_settings_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/pet_sharing_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/profile_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/saved_content_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/settings_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_activity_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_dashboard_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_diagnostics_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_geofence_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_settings_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/smart_collar_tracking_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/treatment_plan_screen.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/screens/vaccination_overview_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/appointment_management_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/clinic_analytics_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/clinic_management_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/consultation_workspace_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/digital_prescription_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/inventory_pharmacy_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/patient_medical_record_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/patient_queue_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/patient_registry_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/todays_appointments_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/treatment_plan_screen.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/screens/vet_dashboard_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/active_rescue_operations_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/emergency_operations_center_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/mission_accepted_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/mission_completed_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/mission_dashboard_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/mission_details_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/nearby_rescue_requests_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/rescue_community_reports_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/rescue_history_screen.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/screens/volunteer_network_screen.dart';
import 'package:petconnect_ai/router/route_guard.dart';
import 'package:petconnect_ai/router/route_observer.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/placeholder_screen.dart';

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
                  GoRoute(
                    path: 'sharing',
                    name: RouteNames.ownerPetSharing,
                    builder: (context, state) => const PetSharingScreen(),
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
              GoRoute(
                path: 'vault',
                name: RouteNames.ownerHealthVault,
                builder: (context, state) => const PetDocumentsVaultScreen(),
              ),
              GoRoute(
                path: 'treatment',
                name: RouteNames.ownerHealthTreatment,
                builder: (context, state) => const TreatmentPlanScreen(),
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
              GoRoute(
                path: 'analysis',
                name: RouteNames.ownerAiAnalysis,
                builder: (context, state) => const AiHealthAnalysisScreen(),
              ),
              GoRoute(
                path: 'diagnostic',
                name: RouteNames.ownerAiDiagnostic,
                builder: (context, state) => const AiDiagnosticCenterScreen(),
              ),
              GoRoute(
                path: 'scan',
                name: RouteNames.ownerAiScan,
                builder: (context, state) => const AiScanIdentifyScreen(),
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
            path: 'lost-dashboard',
            name: RouteNames.ownerLostDashboard,
            builder: (context, state) => const LostPetDashboardScreen(),
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
              GoRoute(
                path: 'search',
                name: RouteNames.ownerCommunitySearch,
                builder: (context, state) => const CommunitySearchScreen(),
              ),
              GoRoute(
                path: 'achievements',
                name: RouteNames.ownerCommunityBadges,
                builder: (context, state) =>
                    const CommunityAchievementsScreen(),
              ),
              GoRoute(
                path: 'saved',
                name: RouteNames.ownerCommunitySaved,
                builder: (context, state) => const SavedContentScreen(),
              ),
              GoRoute(
                path: 'live-feed',
                name: RouteNames.ownerCommunityLiveFeed,
                builder: (context, state) => const LiveActivityFeedScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: RouteNames.ownerProfile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'search',
            name: RouteNames.ownerSearch,
            builder: (context, state) => const GlobalSearchScreen(),
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
        builder: (context, state) => const VetDashboardScreen(),
        routes: [
          GoRoute(
            path: 'queue',
            name: RouteNames.vetQueue,
            builder: (context, state) => const PatientQueueScreen(),
          ),
          GoRoute(
            path: 'appointments',
            name: RouteNames.vetAppointments,
            builder: (context, state) => const TodaysAppointmentsScreen(),
            routes: [
              GoRoute(
                path: 'schedule',
                name: RouteNames.vetAppointmentSchedule,
                builder: (context, state) =>
                    const AppointmentManagementScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'patients',
            name: RouteNames.vetPatients,
            builder: (context, state) => const PatientRegistryScreen(),
            routes: [
              GoRoute(
                path: ':patientId',
                name: RouteNames.vetPatientDetail,
                builder: (context, state) => PatientMedicalRecordScreen(
                  patientId: state.pathParameters['patientId'] ?? 'p1',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'consultation/:appointmentId',
            name: RouteNames.vetConsultation,
            builder: (context, state) => ConsultationWorkspaceScreen(
              appointmentId: state.pathParameters['appointmentId'] ?? 'c1',
            ),
          ),
          GoRoute(
            path: 'prescription/create',
            name: RouteNames.vetPrescription,
            builder: (context, state) => const DigitalPrescriptionScreen(),
          ),
          GoRoute(
            path: 'treatment-plan',
            name: RouteNames.vetTreatmentPlan,
            builder: (context, state) => const VetTreatmentPlanScreen(),
          ),
          GoRoute(
            path: 'clinic',
            name: RouteNames.vetClinicManagement,
            builder: (context, state) => const ClinicManagementScreen(),
          ),
          GoRoute(
            path: 'pharmacy',
            name: RouteNames.vetPharmacy,
            builder: (context, state) => const InventoryPharmacyScreen(),
          ),
          GoRoute(
            path: 'analytics',
            name: RouteNames.vetAnalytics,
            builder: (context, state) => const ClinicAnalyticsScreen(),
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
        builder: (context, state) => const MissionDashboardScreen(),
        routes: [
          GoRoute(
            path: 'operations',
            name: RouteNames.rescueOperations,
            builder: (context, state) => const ActiveRescueOperationsScreen(),
          ),
          GoRoute(
            path: 'requests',
            name: RouteNames.rescueRequests,
            builder: (context, state) => const NearbyRescueRequestsScreen(),
          ),
          GoRoute(
            path: 'eoc',
            name: RouteNames.rescueEmergencyOps,
            builder: (context, state) =>
                const EmergencyOperationsCenterScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: RouteNames.rescueReports,
            builder: (context, state) => const RescueCommunityReportsScreen(),
          ),
          GoRoute(
            path: 'missions/:missionId',
            name: RouteNames.rescueMissionDetail,
            builder: (context, state) => MissionDetailsScreen(
              missionId: state.pathParameters['missionId'] ?? 'm1',
            ),
            routes: [
              GoRoute(
                path: 'accepted',
                name: RouteNames.rescueMissionAccepted,
                builder: (context, state) => MissionAcceptedScreen(
                  missionId: state.pathParameters['missionId'] ?? 'm1',
                ),
              ),
              GoRoute(
                path: 'completed',
                name: RouteNames.rescueMissionCompleted,
                builder: (context, state) => MissionCompletedScreen(
                  missionId: state.pathParameters['missionId'] ?? 'm1',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'history',
            name: RouteNames.rescueHistory,
            builder: (context, state) => const RescueHistoryScreen(),
          ),
          GoRoute(
            path: 'network',
            name: RouteNames.rescueNetwork,
            builder: (context, state) => const VolunteerNetworkScreen(),
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
