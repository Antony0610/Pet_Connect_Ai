import '../../../../core/utils/typedefs.dart';
import '../../../../shared/domain/repository.dart';

/// Domain contract for onboarding state persistence.
///
/// The data layer implements this, delegating to SharedPreferences. The
/// presentation layer (Splash) reads [isComplete] to decide routing;
/// Onboarding calls [complete] on the last page.
abstract interface class OnboardingRepository implements Repository {
  /// Returns `true` if the user has completed onboarding, `false` otherwise.
  ResultFuture<bool> isComplete();

  /// Persists the onboarding-complete flag.
  ResultVoid complete();
}
