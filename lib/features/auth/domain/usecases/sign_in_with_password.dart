import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

class SignInWithPassword implements UseCase<AuthSession, SignInParams> {
  const SignInWithPassword(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession> call(SignInParams params) => _repository
      .signInWithPassword(email: params.email, password: params.password);
}
