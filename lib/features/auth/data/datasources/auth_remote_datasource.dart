import 'package:petconnect_ai/core/error/exceptions.dart' as core_exceptions;
import 'package:petconnect_ai/features/auth/data/models/auth_session_model.dart';
import 'package:petconnect_ai/shared/data/datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for authentication operations via Supabase Auth.
///
/// Throws [core_exceptions.AuthException] when operations fail. The repository
/// catches those and maps them to domain [Failure]s.
abstract interface class AuthRemoteDataSource implements RemoteDataSource {
  /// Returns the current session model if one exists, or `null` if the user
  /// is unauthenticated. Reads the locally persisted Supabase session; does
  /// not make a network request.
  AuthSessionModel? getCurrentSession();

  /// Signs in with email + password against Supabase Auth, returning the
  /// resulting session model.
  Future<AuthSessionModel> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registers a new user with Supabase Auth.
  ///
  /// [fullName] and [phone] are stored as user metadata. When email
  /// confirmation is enabled the returned session is `null`; the caller then
  /// drives the OTP verification step.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// Verifies the sign-up OTP and returns the authenticated session.
  Future<AuthSessionModel> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Re-sends the sign-up confirmation OTP.
  Future<void> resendEmailOtp({required String email});
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
    String? phone,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
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
}
