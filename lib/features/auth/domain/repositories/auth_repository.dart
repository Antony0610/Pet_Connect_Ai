import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/shared/domain/repository.dart';

/// Domain contract for authentication operations.
///
/// The data layer implements this, delegating to Supabase Auth. The
/// presentation layer (Splash) calls [currentSession] to decide routing.
abstract interface class AuthRepository implements Repository {
  /// Returns the current session if one exists, or `null` if the user is
  /// unauthenticated. Checks the locally persisted Supabase session; does not
  /// make a network request.
  ResultFuture<AuthSession?> currentSession();

  /// Signs a user in with their email and password.
  ///
  /// Returns the resulting [AuthSession] on success.
  ResultFuture<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registers a new user. [fullName] and optional [phone] are stored as user
  /// metadata. Completes with no value; the caller drives OTP verification.
  ResultVoid signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// Confirms a newly registered account by verifying the emailed OTP [token],
  /// returning the resulting authenticated [AuthSession].
  ResultFuture<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Re-sends the sign-up confirmation OTP to [email].
  ResultVoid resendEmailOtp({required String email});
}
