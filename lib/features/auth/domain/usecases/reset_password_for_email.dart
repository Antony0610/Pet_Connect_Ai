import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordForEmail implements UseCase<void, String> {
  const ResetPasswordForEmail(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(String email) =>
      _repository.resetPasswordForEmail(email: email);
}
