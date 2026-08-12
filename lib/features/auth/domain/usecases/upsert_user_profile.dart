import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';

class UpsertUserProfile implements UseCase<void, UserProfile> {
  const UpsertUserProfile(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call(UserProfile profile) =>
      _repository.upsertUserProfile(profile);
}
