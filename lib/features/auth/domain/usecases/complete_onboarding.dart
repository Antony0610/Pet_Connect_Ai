import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/onboarding_repository.dart';

/// Marks the onboarding flow as complete so it is not shown again.
class CompleteOnboarding implements UseCase<void, NoParams> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  ResultVoid call(NoParams params) => _repository.complete();
}
