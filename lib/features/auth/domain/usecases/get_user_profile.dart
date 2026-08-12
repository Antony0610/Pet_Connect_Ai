import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class GetUserProfile implements UseCase<UserProfile?, String> {
  const GetUserProfile(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<UserProfile?> call(String userId) =>
      _repository.getUserProfile(userId: userId);
}
