import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/shared/data/model.dart';

/// Data-layer model (DTO) for [AuthSession].
///
/// Maps from the raw Supabase [Session] DTO to the domain entity. This keeps
/// Supabase types out of the domain and presentation layers.
class AuthSessionModel implements Model {
  const AuthSessionModel({required this.userId, required this.email});

  final String userId;
  final String? email;

  /// Creates a model from the raw Supabase [Session].
  factory AuthSessionModel.fromSupabase(Session session) =>
      AuthSessionModel(userId: session.user.id, email: session.user.email);

  /// Maps this DTO to the domain [AuthSession] entity.
  AuthSession toEntity() => AuthSession(userId: userId, email: email);

  @override
  Json toJson() => {'userId': userId, 'email': email};
}
