import '../../../../shared/domain/entity.dart';

/// The user's active session (domain entity).
///
/// Returned by [AuthRepository.currentSession] when a valid Supabase session
/// exists. `null` means unauthenticated. Holds only the identity facts the
/// domain cares about (user ID, email); the data layer maps from the raw
/// Supabase `Session` DTO.
class AuthSession extends Entity {
  const AuthSession({required this.userId, required this.email});

  final String userId;
  final String? email;

  @override
  List<Object?> get props => [userId, email];
}
