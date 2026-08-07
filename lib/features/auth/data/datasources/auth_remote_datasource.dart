import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart' as core_exceptions;
import '../../../../shared/data/datasource.dart';
import '../models/auth_session_model.dart';

/// Remote data source for authentication operations via Supabase Auth.
///
/// Throws [core_exceptions.AuthException] when operations fail. The repository
/// catches those and maps them to domain [Failure]s.
abstract interface class AuthRemoteDataSource implements RemoteDataSource {
  /// Returns the current session model if one exists, or `null` if the user
  /// is unauthenticated. Reads the locally persisted Supabase session; does
  /// not make a network request.
  AuthSessionModel? getCurrentSession();
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
}
