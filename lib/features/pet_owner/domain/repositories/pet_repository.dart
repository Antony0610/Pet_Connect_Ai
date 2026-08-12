import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/shared/domain/repository.dart';

/// Domain contract for core Pet management operations.
abstract interface class PetRepository implements Repository {
  /// Fetches all pets owned by the currently authenticated user.
  ResultFuture<List<Pet>> getPets();

  /// Fetches a specific pet owned by the currently authenticated user by [id].
  ResultFuture<Pet?> getPetById(String id);

  /// Creates a new pet for the currently authenticated user.
  ResultFuture<Pet> createPet(Pet pet);

  /// Updates an existing pet owned by the currently authenticated user.
  ResultFuture<Pet> updatePet(Pet pet);

  /// Deletes a pet owned by the currently authenticated user by [id].
  ResultVoid deletePet(String id);

  /// Reads pet preference settings for [petId].
  ResultFuture<PetSettings?> getPetSettings(String petId);

  /// Saves pet preference settings for [petId].
  ResultVoid updatePetSettings(PetSettings settings);
}
