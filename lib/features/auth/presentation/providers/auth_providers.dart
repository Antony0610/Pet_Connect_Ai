import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petconnect_ai/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:petconnect_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:petconnect_ai/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/complete_onboarding.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/create_account.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/get_current_session.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/get_user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/is_onboarding_complete.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/resend_email_otp.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/reset_password_for_email.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_out.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/upsert_user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/verify_email_otp.dart';
import 'package:petconnect_ai/router/route_paths.dart';

// ──────────────────────────────────────────────────────────────────
// Data sources
// ──────────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider)),
);

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>(
  (ref) => OnboardingLocalDataSourceImpl(ref.watch(sharedPreferencesProvider)),
);

// ──────────────────────────────────────────────────────────────────
// Repositories
// ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) =>
      OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider)),
);

// ──────────────────────────────────────────────────────────────────
// Use cases
// ──────────────────────────────────────────────────────────────────

final getCurrentSessionProvider = Provider<GetCurrentSession>(
  (ref) => GetCurrentSession(ref.watch(authRepositoryProvider)),
);

final isOnboardingCompleteProvider = Provider<IsOnboardingComplete>(
  (ref) => IsOnboardingComplete(ref.watch(onboardingRepositoryProvider)),
);

final completeOnboardingProvider = Provider<CompleteOnboarding>(
  (ref) => CompleteOnboarding(ref.watch(onboardingRepositoryProvider)),
);

final signInWithPasswordProvider = Provider<SignInWithPassword>(
  (ref) => SignInWithPassword(ref.watch(authRepositoryProvider)),
);

final createAccountProvider = Provider<CreateAccount>(
  (ref) => CreateAccount(ref.watch(authRepositoryProvider)),
);

final verifyEmailOtpProvider = Provider<VerifyEmailOtp>(
  (ref) => VerifyEmailOtp(ref.watch(authRepositoryProvider)),
);

final resendEmailOtpProvider = Provider<ResendEmailOtp>(
  (ref) => ResendEmailOtp(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final resetPasswordForEmailProvider = Provider<ResetPasswordForEmail>(
  (ref) => ResetPasswordForEmail(ref.watch(authRepositoryProvider)),
);

final getUserProfileProvider = Provider<GetUserProfile>(
  (ref) => GetUserProfile(ref.watch(authRepositoryProvider)),
);

final upsertUserProfileProvider = Provider<UpsertUserProfile>(
  (ref) => UpsertUserProfile(ref.watch(authRepositoryProvider)),
);

/// Transient signup state: pending verification email.
final pendingVerificationEmailProvider = StateProvider<String?>((ref) => null);

/// Transient signup state: selected role portal on Role Selection screen.
final selectedPortalProvider = StateProvider<AppPortal>(
  (ref) => AppPortal.petOwner,
);

/// Asynchronously resolves the currently authenticated user's profile.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final getCurrentSession = ref.watch(getCurrentSessionProvider);
  final sessionResult = await getCurrentSession(const NoParams());
  final session = sessionResult.fold((_) => null, (s) => s);

  if (session == null) return null;

  final getUserProfile = ref.watch(getUserProfileProvider);
  final profileResult = await getUserProfile(session.userId);
  return profileResult.fold((_) => null, (profile) => profile);
});

/// Resolves the Splash screen's destination.
///
/// Decision tree:
/// - No session + onboarding incomplete → onboarding
/// - No session + onboarding complete → login
/// - Session exists → portal home matching user's role (owner, vet, rescue, admin)
final splashDestinationProvider = FutureProvider<String>((ref) async {
  final getCurrentSession = ref.watch(getCurrentSessionProvider);
  final isOnboardingComplete = ref.watch(isOnboardingCompleteProvider);

  // Check session
  final sessionResult = await getCurrentSession(const NoParams());
  final session = sessionResult.fold((_) => null, (session) => session);

  // Authenticated → route to portal matching profile role
  if (session != null) {
    final getUserProfile = ref.watch(getUserProfileProvider);
    final profileResult = await getUserProfile(session.userId);
    final profile = profileResult.fold((_) => null, (p) => p);

    final portal = profile?.role ?? AppPortal.petOwner;
    return switch (portal) {
      AppPortal.petOwner => RoutePaths.ownerHome,
      AppPortal.veterinarian => RoutePaths.vetHome,
      AppPortal.volunteerRescue => RoutePaths.rescueHome,
      AppPortal.administrator => RoutePaths.adminHome,
    };
  }

  // Unauthenticated → onboarding or login
  final onboardingResult = await isOnboardingComplete(const NoParams());
  final hasSeenOnboarding = onboardingResult.fold(
    (_) => false,
    (complete) => complete,
  );

  return hasSeenOnboarding ? RoutePaths.login : RoutePaths.onboarding;
});
