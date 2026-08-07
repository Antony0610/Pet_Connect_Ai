import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../router/route_paths.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/onboarding_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/is_onboarding_complete.dart';

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

// ──────────────────────────────────────────────────────────────────
// Presentation logic
// ──────────────────────────────────────────────────────────────────

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
