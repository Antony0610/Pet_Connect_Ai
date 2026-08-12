import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  const SignOut(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(NoParams params) => _repository.signOut();
}
