import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

class DeletePet implements UseCase<void, String> {
  const DeletePet(this._repository);

  final PetRepository _repository;

  @override
  ResultVoid call(String id) => _repository.deletePet(id);
}
