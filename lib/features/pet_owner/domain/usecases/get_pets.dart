import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class GetPets implements UseCase<List<Pet>, NoParams> {
  const GetPets(this._repository);

  final PetRepository _repository;

  @override
  ResultFuture<List<Pet>> call(NoParams params) => _repository.getPets();
}
