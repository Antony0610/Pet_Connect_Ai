import '../../../../core/utils/typedefs.dart';
import '../../../../shared/domain/repository.dart';
import '../entities/auth_session.dart';

/// Domain contract for authentication operations.
///
/// The data layer implements this, delegating to Supabase Auth. The
/// presentation layer (Splash) calls [currentSession] to decide routing.
abstract interface class AuthRepository implements Repository {
  /// Returns the current session if one exists, or `null` if the user is
  /// unauthenticated. Checks the locally persisted Supabase session; does not
  /// make a network request.
  ResultFuture<AuthSession?> currentSession();
}
