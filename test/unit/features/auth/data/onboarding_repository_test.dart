import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:petconnect_ai/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/complete_onboarding.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/is_onboarding_complete.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Persistence & UseCases Unit Tests', () {
    test('OnboardingLocalDataSourceImpl reads and writes completion flag', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = OnboardingLocalDataSourceImpl(prefs);

      expect(dataSource.isComplete(), isFalse);

      await dataSource.complete();
      expect(dataSource.isComplete(), isTrue);
    });

    test('OnboardingRepositoryImpl returns completion state on success', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = OnboardingLocalDataSourceImpl(prefs);
      final repository = OnboardingRepositoryImpl(dataSource);

      final result = await repository.isComplete();
      result.fold(
        (failure) => fail('Should not return failure'),
        (isComplete) => expect(isComplete, isTrue),
      );
    });

    test('CompleteOnboarding use case persists state via repository', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = OnboardingLocalDataSourceImpl(prefs);
      final repository = OnboardingRepositoryImpl(dataSource);
      final usecase = CompleteOnboarding(repository);

      final result = await usecase(const NoParams());
      expect(result.isRight(), isTrue);

      final isCompleteResult = await IsOnboardingComplete(repository)(const NoParams());
      expect(isCompleteResult.getOrElse(() => false), isTrue);
    });
  });
}
