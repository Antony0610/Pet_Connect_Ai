import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class GetPetById implements UseCase<Pet?, String> {
  const GetPetById(this._repository);

  final PetRepository _repository;

  @override
  ResultFuture<Pet?> call(String id) => _repository.getPetById(id);
}
