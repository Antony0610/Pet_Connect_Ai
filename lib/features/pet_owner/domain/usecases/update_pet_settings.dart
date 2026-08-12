import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class UpdatePetSettings implements UseCase<void, PetSettings> {
  const UpdatePetSettings(this._repository);

  final PetRepository _repository;

  @override
  ResultVoid call(PetSettings settings) =>
      _repository.updatePetSettings(settings);
}
