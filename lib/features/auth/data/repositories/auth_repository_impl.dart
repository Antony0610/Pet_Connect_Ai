import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Supabase-backed implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  ResultFuture<AuthSession?> currentSession() async {
    try {
      final model = _remote.getCurrentSession();
      return Right(model?.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      await _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final model = await _remote.verifyEmailOtp(email: email, token: token);
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid resendEmailOtp({required String email}) async {
    try {
      await _remote.resendEmailOtp(email: email);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }
}
