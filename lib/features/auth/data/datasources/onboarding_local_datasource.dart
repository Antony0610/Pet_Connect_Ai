import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../shared/data/datasource.dart';

/// Local data source for onboarding state persistence via SharedPreferences.
///
/// Throws [CacheException] when operations fail. The repository catches those
/// and maps them to domain [Failure]s.
abstract interface class OnboardingLocalDataSource implements LocalDataSource {
  /// Returns `true` if the user has completed onboarding, `false` otherwise.
  bool isComplete();

  /// Persists the onboarding-complete flag.
  Future<void> complete();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'onboarding_complete';

  @override
  bool isComplete() {
    try {
      return _prefs.getBool(_key) ?? false;
    } catch (e) {
      throw CacheException('Failed to read onboarding state', cause: e);
    }
  }

  @override
  Future<void> complete() async {
    try {
      final success = await _prefs.setBool(_key, true);
      if (!success) {
        throw CacheException('Failed to persist onboarding completion');
      }
    } catch (e) {
      throw CacheException('Failed to persist onboarding state', cause: e);
    }
  }
}
