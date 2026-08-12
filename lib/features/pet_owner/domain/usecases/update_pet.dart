import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class UpdatePet implements UseCase<Pet, Pet> {
  const UpdatePet(this._repository);

  final PetRepository _repository;

  @override
  ResultFuture<Pet> call(Pet pet) => _repository.updatePet(pet);
}
