import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Returns the current [AuthSession], or `null` if unauthenticated.
class GetCurrentSession implements UseCase<AuthSession?, NoParams> {
  const GetCurrentSession(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession?> call(NoParams params) =>
      _repository.currentSession();
}
