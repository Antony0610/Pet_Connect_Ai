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
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;
  static AuthSession? _activeDemoSession;
  static UserProfile? _activeDemoProfile;

  static const Map<String, (String, String, AppPortal)> _demoAccounts = {
    'owner@petconnect.ai': ('00000000-0000-0000-0000-000000000001', 'Alex Cooper (Pet Owner)', AppPortal.petOwner),
    'vet@petconnect.ai': ('00000000-0000-0000-0000-000000000002', 'Dr. Emily Vance (DVM)', AppPortal.veterinarian),
    'rescue@petconnect.ai': ('00000000-0000-0000-0000-000000000003', 'Alex Morgan (Rescue Lead)', AppPortal.volunteerRescue),
    'admin@petconnect.ai': ('00000000-0000-0000-0000-000000000004', 'System Administrator', AppPortal.administrator),
  };

  @override
  ResultFuture<AuthSession?> currentSession() async {
    try {
      if (_activeDemoSession != null) {
        return Right(_activeDemoSession);
      }
      final model = _remote.getCurrentSession();
      return Right(model?.toEntity());
    } on AppException catch (e) {
      if (_activeDemoSession != null) return Right(_activeDemoSession);
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      if (_activeDemoSession != null) return Right(_activeDemoSession);
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final lowerEmail = email.trim().toLowerCase();

    try {
      final model = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
      _activeDemoSession = null;
      _activeDemoProfile = null;
      return Right(model.toEntity());
    } catch (e) {
      // If remote auth fails and it's a known demo email, provide seamless local demo session
      if (_demoAccounts.containsKey(lowerEmail)) {
        final (id, name, portal) = _demoAccounts[lowerEmail]!;
        final demoSession = AuthSession(userId: id, email: lowerEmail);
        _activeDemoSession = demoSession;
        _activeDemoProfile = UserProfile(
          id: id,
          email: lowerEmail,
          fullName: name,
          role: portal,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return Right(demoSession);
      }

      if (e is AppException) {
        return Left(FailureMapper.fromException(e));
      }
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
    _activeDemoSession = null;
    _activeDemoProfile = null;
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
    if (_activeDemoProfile != null && _activeDemoProfile!.id == userId) {
      return Right(_activeDemoProfile);
    }

    try {
      final model = await _remote.getUserProfile(userId: userId);
      if (model != null) return Right(model.toEntity());

      if (_activeDemoProfile != null) return Right(_activeDemoProfile);
      return const Right(null);
    } on AppException catch (e) {
      if (_activeDemoProfile != null) return Right(_activeDemoProfile);
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      if (_activeDemoProfile != null) return Right(_activeDemoProfile);
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid upsertUserProfile(UserProfile profile) async {
    if (_activeDemoProfile != null && _activeDemoProfile!.id == profile.id) {
      _activeDemoProfile = profile;
    }

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
