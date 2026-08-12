import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class CreateAccountParams {
  const CreateAccountParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.role = AppPortal.petOwner,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final AppPortal role;
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
    role: params.role,
    phone: params.phone,
  );
}
