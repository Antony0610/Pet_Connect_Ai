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
  static const String ownerPetDetail = '/owner/pets/:petId';
  static const String ownerHealth = '/owner/health';
  static const String ownerAiAssistant = '/owner/ai';
  static const String ownerCollar = '/owner/collar';
  static const String ownerCommunity = '/owner/community';
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
  static const String ownerPetDetail = 'ownerPetDetail';
  static const String ownerHealth = 'ownerHealth';
  static const String ownerAiAssistant = 'ownerAiAssistant';
  static const String ownerCollar = 'ownerCollar';
  static const String ownerCommunity = 'ownerCommunity';
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
