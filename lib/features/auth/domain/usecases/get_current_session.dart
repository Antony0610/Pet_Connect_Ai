import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

/// Returns the current [AuthSession], or `null` if unauthenticated.
class GetCurrentSession implements UseCase<AuthSession?, NoParams> {
  const GetCurrentSession(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession?> call(NoParams params) =>
      _repository.currentSession();
}
