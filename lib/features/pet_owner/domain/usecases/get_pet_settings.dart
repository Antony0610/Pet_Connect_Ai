import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class GetPetSettings implements UseCase<PetSettings?, String> {
  const GetPetSettings(this._repository);

  final PetRepository _repository;

  @override
  ResultFuture<PetSettings?> call(String petId) =>
      _repository.getPetSettings(petId);
}
