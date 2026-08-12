import 'package:petconnect_ai/core/error/exceptions.dart' as core_exceptions;
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/features/auth/data/models/auth_session_model.dart';
import 'package:petconnect_ai/features/auth/data/models/user_profile_model.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/shared/data/datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for authentication operations via Supabase Auth & Database.
abstract interface class AuthRemoteDataSource implements RemoteDataSource {
  /// Returns current persisted session model, if available.
  AuthSessionModel? getCurrentSession();

  /// Signs in with email + password against Supabase Auth.
  Future<AuthSessionModel> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registers a new user with Supabase Auth.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppPortal role,
    String? phone,
  });

  /// Verifies sign-up OTP code and returns authenticated session.
  Future<AuthSessionModel> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Re-sends sign-up confirmation OTP.
  Future<void> resendEmailOtp({required String email});

  /// Signs out current session.
  Future<void> signOut();

  /// Dispatches password reset email.
  Future<void> resetPasswordForEmail({required String email});

  /// Reads user profile from `profiles` table.
  Future<UserProfileModel?> getUserProfile({required String userId});

  /// Writes/updates user profile to `profiles` table.
  Future<void> upsertUserProfile(UserProfileModel profile);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  AuthSessionModel? getCurrentSession() {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      return AuthSessionModel.fromSupabase(session);
    } catch (e) {
      throw core_exceptions.AuthException(
        'Failed to retrieve current session',
        cause: e,
      );
    }
  }

  @override
  Future<AuthSessionModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session == null) {
        throw const core_exceptions.AuthException(
          'Sign in did not return a session',
        );
      }
      return AuthSessionModel.fromSupabase(session);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on core_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw core_exceptions.AuthException('Failed to sign in', cause: e);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppPortal role,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.toDbRole(),
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      final user = response.user;
      if (user != null) {
        // Persist default profile row in public.profiles table
        final profileModel = UserProfileModel(
          id: user.id,
          email: email,
          fullName: fullName,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await upsertUserProfile(profileModel);
      }
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException('Failed to create account', cause: e);
    }
  }

  @override
  Future<AuthSessionModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      final session = response.session;
      if (session == null) {
        throw const core_exceptions.AuthException(
          'Verification did not return a session',
        );
      }

      // Ensure profile row exists after confirmation
      final user = session.user;
      final existing = await getUserProfile(userId: user.id);
      if (existing == null) {
        final fullName = user.userMetadata?['full_name'] as String? ?? 'Pet Owner';
        final roleStr = user.userMetadata?['role'] as String?;
        final role = AppPortalExtension.fromDbRole(roleStr);
        await upsertUserProfile(
          UserProfileModel(
            id: user.id,
            email: user.email ?? email,
            fullName: fullName,
            role: role,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return AuthSessionModel.fromSupabase(session);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on core_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw core_exceptions.AuthException('Failed to verify code', cause: e);
    }
  }

  @override
  Future<void> resendEmailOtp({required String email}) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException('Failed to resend code', cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException('Failed to sign out', cause: e);
    }
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException(
        'Failed to send password reset request',
        cause: e,
      );
    }
  }

  @override
  Future<UserProfileModel?> getUserProfile({required String userId}) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfileModel.fromJson(data);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException(
        'Failed to load user profile',
        cause: e,
      );
    }
  }

  @override
  Future<void> upsertUserProfile(UserProfileModel profile) async {
    try {
      await _client.from('profiles').upsert(profile.toJson());
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.AuthException('Failed to save profile', cause: e);
    }
  }
}
