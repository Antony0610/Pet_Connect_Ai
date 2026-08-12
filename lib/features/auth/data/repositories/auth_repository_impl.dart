import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petconnect_ai/features/auth/data/models/user_profile_model.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

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
    required AppPortal role,
    String? phone,
  }) async {
    try {
      await _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
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

  @override
  ResultVoid signOut() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid resetPasswordForEmail({required String email}) async {
    try {
      await _remote.resetPasswordForEmail(email: email);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<UserProfile?> getUserProfile({required String userId}) async {
    try {
      final model = await _remote.getUserProfile(userId: userId);
      return Right(model?.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid upsertUserProfile(UserProfile profile) async {
    try {
      await _remote.upsertUserProfile(UserProfileModel.fromEntity(profile));
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }
}
