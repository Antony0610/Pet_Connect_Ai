import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/shared/domain/repository.dart';

/// Domain contract for authentication and user profile operations.
abstract interface class AuthRepository implements Repository {
  /// Returns the current session if one exists, or `null` if the user is
  /// unauthenticated. Checks the locally persisted Supabase session.
  ResultFuture<AuthSession?> currentSession();

  /// Signs a user in with email and password.
  ResultFuture<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registers a new user. [fullName], [role], and optional [phone] are stored as
  /// user metadata and initialized in the database profile.
  ResultVoid signUp({
    required String email,
    required String password,
    required String fullName,
    required AppPortal role,
    String? phone,
  });

  /// Confirms account via emailed OTP token.
  ResultFuture<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Re-sends sign-up confirmation OTP to [email].
  ResultVoid resendEmailOtp({required String email});

  /// Signs out the currently authenticated user.
  ResultVoid signOut();

  /// Dispatches a password reset email to [email].
  ResultVoid resetPasswordForEmail({required String email});

  /// Fetches the user profile associated with [userId] from `profiles` table.
  ResultFuture<UserProfile?> getUserProfile({required String userId});

  /// Inserts or updates a user profile in `profiles` table.
  ResultVoid upsertUserProfile(UserProfile profile);
}
