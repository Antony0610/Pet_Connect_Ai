import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class ResendEmailOtp implements UseCase<void, String> {
  const ResendEmailOtp(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(String email) => _repository.resendEmailOtp(email: email);
}
