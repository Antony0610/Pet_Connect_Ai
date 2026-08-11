import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petconnect_ai/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:petconnect_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:petconnect_ai/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/complete_onboarding.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/create_account.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/get_current_session.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/is_onboarding_complete.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/resend_email_otp.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_in_with_password.dart';
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

/// The email currently being verified, carried from Create Account into the
/// OTP screen. Transient signup state — cleared once verification completes.
final pendingVerificationEmailProvider = StateProvider<String?>((ref) => null);

// ──────────────────────────────────────────────────────────────────
// Presentation logic
// ──────────────────────────────────────────────────────────────────

/// The portal the user picks on the Role Selection screen.
///
/// Transient signup state — defaults to [AppPortal.petOwner] (the design's
/// default-selected card) and drives which portal identity the subsequent
/// auth screens carry. Not persisted; the durable role is written server-side
/// once the account is created.
final selectedPortalProvider = StateProvider<AppPortal>(
  (ref) => AppPortal.petOwner,
);

/// Resolves the Splash screen's destination.
///
/// Reads the current session and onboarding state and returns the path Splash
/// should navigate to after its minimum display duration. The Splash screen
/// watches this and navigates once it resolves.
///
/// Decision tree:
/// - No session + onboarding incomplete → onboarding
/// - No session + onboarding complete → login
/// - Session exists → owner home (placeholder; role-based routing comes later)
final splashDestinationProvider = FutureProvider<String>((ref) async {
  final getCurrentSession = ref.watch(getCurrentSessionProvider);
  final isOnboardingComplete = ref.watch(isOnboardingCompleteProvider);

  // Check session
  final sessionResult = await getCurrentSession(const NoParams());
  final session = sessionResult.fold(
    (_) => null, // Treat auth failure as unauthenticated
    (session) => session,
  );

  // Authenticated → portal home (placeholder; role-based routing later)
  if (session != null) {
    return RoutePaths.ownerHome;
  }

  // Unauthenticated → onboarding or login
  final onboardingResult = await isOnboardingComplete(const NoParams());
  final hasSeenOnboarding = onboardingResult.fold(
    (_) => false, // Treat onboarding-check failure as incomplete
    (complete) => complete,
  );

  return hasSeenOnboarding ? RoutePaths.login : RoutePaths.onboarding;
});
