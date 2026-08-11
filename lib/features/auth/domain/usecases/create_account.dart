import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class CreateAccountParams {
  const CreateAccountParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;
}

class CreateAccount implements UseCase<void, CreateAccountParams> {
  const CreateAccount(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(CreateAccountParams params) => _repository.signUp(
    email: params.email,
    password: params.password,
    fullName: params.fullName,
    phone: params.phone,
  );
}
