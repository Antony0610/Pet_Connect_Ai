import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/onboarding_repository.dart';

/// Returns whether the user has completed the onboarding flow.
class IsOnboardingComplete implements UseCase<bool, NoParams> {
  const IsOnboardingComplete(this._repository);

  final OnboardingRepository _repository;

  @override
  ResultFuture<bool> call(NoParams params) => _repository.isComplete();
}
