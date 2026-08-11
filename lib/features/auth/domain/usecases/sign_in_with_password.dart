import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

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
