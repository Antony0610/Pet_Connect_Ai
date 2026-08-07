import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailOtpParams {
  const VerifyEmailOtpParams({required this.email, required this.token});

  final String email;
  final String token;
}

/// Confirms a freshly created account by verifying the emailed OTP code,
/// returning the now-authenticated [AuthSession].
class VerifyEmailOtp implements UseCase<AuthSession, VerifyEmailOtpParams> {
  const VerifyEmailOtp(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession> call(VerifyEmailOtpParams params) =>
      _repository.verifyEmailOtp(email: params.email, token: params.token);
}
