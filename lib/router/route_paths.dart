/// Canonical route paths and names for the entire app.
///
/// Every navigable location is declared here as a `static const` so call sites
/// reference symbols, never string literals. Paths are grouped by portal.
/// Route *names* (used with `context.goNamed`) mirror the path leaf.
///
/// NOTE: These are the navigation contracts only. Screen widgets are stubbed
/// during the foundation phase and filled in during each feature's phase.
abstract final class RoutePaths {
  const RoutePaths._();

  // ── Root / shared ──────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ── Auth ───────────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String roleSelection = '/role-selection';
  static const String otpVerification = '/verify-otp';
  static const String welcomeSuccess = '/welcome';
  static const String initialPetSetup = '/pet-setup';

  // ── Pet Owner portal (primary) ─────────────────────────────────
  static const String ownerHome = '/owner';
  static const String ownerPets = '/owner/pets';
  static const String ownerPetAdd = '/owner/pets/add';
  static const String ownerPetDetail = '/owner/pets/:petId';
  static const String ownerPetEdit = '/owner/pets/:petId/edit';
  static const String ownerPetSettings = '/owner/pets/:petId/settings';
  static const String ownerPetDelete = '/owner/pets/:petId/delete';
  static const String ownerPetGallery = '/owner/pets/:petId/gallery';
  static const String ownerPetSharing = '/owner/pets/sharing';
  static const String ownerLostDashboard = '/owner/lost-dashboard';
  static const String ownerHealth = '/owner/health';
  static const String ownerHealthMedical = '/owner/health/medical';
  static const String ownerHealthVaccinations = '/owner/health/vaccinations';
  static const String ownerHealthTimeline = '/owner/health/timeline';
  static const String ownerHealthGrowth = '/owner/health/growth';
  static const String ownerHealthVault = '/owner/health/vault';
  static const String ownerHealthTreatment = '/owner/health/treatment';
  static const String ownerAiAssistant = '/owner/ai';
  static const String ownerAiChat = '/owner/ai/chat';
  static const String ownerAiInsights = '/owner/ai/insights';
  static const String ownerAiRecommendations = '/owner/ai/recommendations';
  static const String ownerAiReports = '/owner/ai/reports';
  static const String ownerAiHistory = '/owner/ai/history';
  static const String ownerAiAnalysis = '/owner/ai/analysis';
  static const String ownerAiDiagnostic = '/owner/ai/diagnostic';
  static const String ownerAiScan = '/owner/ai/scan';
  static const String ownerCollar = '/owner/collar';
  static const String ownerCollarTracking = '/owner/collar/tracking';
  static const String ownerCollarActivity = '/owner/collar/activity';
  static const String ownerCollarGeofence = '/owner/collar/geofence';
  static const String ownerCollarDiagnostics = '/owner/collar/diagnostics';
  static const String ownerCollarSettings = '/owner/collar/settings';
  static const String ownerLostMode = '/owner/lost-mode';
  static const String ownerCommunity = '/owner/community';
  static const String ownerCommunityCreatePost = '/owner/community/create-post';
  static const String ownerCommunityDiscover = '/owner/community/discover';
  static const String ownerCommunityLocal = '/owner/community/local';
  static const String ownerCommunitySightings = '/owner/community/sightings';
  static const String ownerCommunityLostFound = '/owner/community/lost-found';
  static const String ownerCommunityEvents = '/owner/community/events';
  static const String ownerCommunityAdoption = '/owner/community/adoption';
  static const String ownerCommunityMessages = '/owner/community/messages';
  static const String ownerCommunitySearch = '/owner/community/search';
  static const String ownerCommunityBadges = '/owner/community/achievements';
  static const String ownerCommunitySaved = '/owner/community/saved';
  static const String ownerCommunityLiveFeed = '/owner/community/live-feed';
  static const String ownerNotifications = '/owner/notifications';
  static const String ownerSearch = '/owner/search';
  static const String ownerProfile = '/owner/profile';
  static const String ownerSettings = '/owner/settings';

  // ── Veterinarian portal ────────────────────────────────────────
  static const String vetHome = '/vet';
  static const String vetAppointments = '/vet/appointments';
  static const String vetPatients = '/vet/patients';
  static const String vetPatientDetail = '/vet/patients/:patientId';
  static const String vetProfile = '/vet/profile';

  // ── Volunteer & Rescue portal ──────────────────────────────────
  static const String rescueHome = '/rescue';
  static const String rescueCases = '/rescue/cases';
  static const String rescueCaseDetail = '/rescue/cases/:caseId';
  static const String rescueMap = '/rescue/map';
  static const String rescueProfile = '/rescue/profile';

  // ── Administrator portal ───────────────────────────────────────
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminModeration = '/admin/moderation';
  static const String adminAnalytics = '/admin/analytics';

  // ── Error ──────────────────────────────────────────────────────
  static const String notFound = '/404';
}

/// Route names for named navigation.
abstract final class RouteNames {
  const RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';

  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String roleSelection = 'roleSelection';
  static const String otpVerification = 'otpVerification';
  static const String welcomeSuccess = 'welcomeSuccess';
  static const String initialPetSetup = 'initialPetSetup';

  static const String ownerHome = 'ownerHome';
  static const String ownerPets = 'ownerPets';
  static const String ownerPetAdd = 'ownerPetAdd';
  static const String ownerPetDetail = 'ownerPetDetail';
  static const String ownerPetEdit = 'ownerPetEdit';
  static const String ownerPetSettings = 'ownerPetSettings';
  static const String ownerPetDelete = 'ownerPetDelete';
  static const String ownerPetGallery = 'ownerPetGallery';
  static const String ownerPetSharing = 'ownerPetSharing';
  static const String ownerLostDashboard = 'ownerLostDashboard';
  static const String ownerHealth = 'ownerHealth';
  static const String ownerHealthMedical = 'ownerHealthMedical';
  static const String ownerHealthVaccinations = 'ownerHealthVaccinations';
  static const String ownerHealthTimeline = 'ownerHealthTimeline';
  static const String ownerHealthGrowth = 'ownerHealthGrowth';
  static const String ownerHealthVault = 'ownerHealthVault';
  static const String ownerHealthTreatment = 'ownerHealthTreatment';
  static const String ownerAiAssistant = 'ownerAiAssistant';
  static const String ownerAiChat = 'ownerAiChat';
  static const String ownerAiInsights = 'ownerAiInsights';
  static const String ownerAiRecommendations = 'ownerAiRecommendations';
  static const String ownerAiReports = 'ownerAiReports';
  static const String ownerAiHistory = 'ownerAiHistory';
  static const String ownerAiAnalysis = 'ownerAiAnalysis';
  static const String ownerAiDiagnostic = 'ownerAiDiagnostic';
  static const String ownerAiScan = 'ownerAiScan';
  static const String ownerCollar = 'ownerCollar';
  static const String ownerCollarTracking = 'ownerCollarTracking';
  static const String ownerCollarActivity = 'ownerCollarActivity';
  static const String ownerCollarGeofence = 'ownerCollarGeofence';
  static const String ownerCollarDiagnostics = 'ownerCollarDiagnostics';
  static const String ownerCollarSettings = 'ownerCollarSettings';
  static const String ownerLostMode = 'ownerLostMode';
  static const String ownerCommunity = 'ownerCommunity';
  static const String ownerCommunityCreatePost = 'ownerCommunityCreatePost';
  static const String ownerCommunityDiscover = 'ownerCommunityDiscover';
  static const String ownerCommunityLocal = 'ownerCommunityLocal';
  static const String ownerCommunitySightings = 'ownerCommunitySightings';
  static const String ownerCommunityLostFound = 'ownerCommunityLostFound';
  static const String ownerCommunityEvents = 'ownerCommunityEvents';
  static const String ownerCommunityAdoption = 'ownerCommunityAdoption';
  static const String ownerCommunityMessages = 'ownerCommunityMessages';
  static const String ownerCommunitySearch = 'ownerCommunitySearch';
  static const String ownerCommunityBadges = 'ownerCommunityBadges';
  static const String ownerCommunitySaved = 'ownerCommunitySaved';
  static const String ownerCommunityLiveFeed = 'ownerCommunityLiveFeed';
  static const String ownerNotifications = 'ownerNotifications';
  static const String ownerSearch = 'ownerSearch';
  static const String ownerProfile = 'ownerProfile';
  static const String ownerSettings = 'ownerSettings';

  static const String vetHome = 'vetHome';
  static const String vetAppointments = 'vetAppointments';
  static const String vetPatients = 'vetPatients';
  static const String vetPatientDetail = 'vetPatientDetail';
  static const String vetProfile = 'vetProfile';

  static const String rescueHome = 'rescueHome';
  static const String rescueCases = 'rescueCases';
  static const String rescueCaseDetail = 'rescueCaseDetail';
  static const String rescueMap = 'rescueMap';
  static const String rescueProfile = 'rescueProfile';

  static const String adminHome = 'adminHome';
  static const String adminUsers = 'adminUsers';
  static const String adminModeration = 'adminModeration';
  static const String adminAnalytics = 'adminAnalytics';
}
