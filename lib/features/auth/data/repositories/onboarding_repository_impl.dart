import 'package:dartz/dartz.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/onboarding_repository.dart';

/// SharedPreferences-backed implementation of [OnboardingRepository].
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  ResultFuture<bool> isComplete() async {
    try {
      return Right(_local.isComplete());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid complete() async {
    try {
      await _local.complete();
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }
}
