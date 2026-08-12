import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/create_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/delete_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pet_by_id.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pets.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/update_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/update_pet_settings.dart';

class MockPetRepository implements PetRepository {
  final List<Pet> _pets = [];
  final Map<String, PetSettings> _settings = {};

  @override
  ResultFuture<List<Pet>> getPets() async => Right(_pets);

  @override
  ResultFuture<Pet?> getPetById(String id) async =>
      Right(_pets.where((p) => p.id == id).firstOrNull);

  @override
  ResultFuture<Pet> createPet(Pet pet) async {
    _pets.add(pet);
    return Right(pet);
  }

  @override
  ResultFuture<Pet> updatePet(Pet pet) async {
    _pets.removeWhere((p) => p.id == pet.id);
    _pets.add(pet);
    return Right(pet);
  }

  @override
  ResultVoid deletePet(String id) async {
    _pets.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  ResultFuture<PetSettings?> getPetSettings(String petId) async =>
      Right(_settings[petId]);

  @override
  ResultVoid updatePetSettings(PetSettings settings) async {
    _settings[settings.petId] = settings;
    return const Right(null);
  }
}

void main() {
  late MockPetRepository mockRepository;

  setUp(() {
    mockRepository = MockPetRepository();
  });

  const tPet = Pet(
    id: 'pet-1',
    ownerId: 'owner-1',
    name: 'Max',
    species: 'dog',
  );

  group('Pet UseCases', () {
    test('CreatePet should delegate to repository', () async {
      final useCase = CreatePet(mockRepository);
      final result = await useCase(tPet);
      expect(result.isRight(), isTrue);
    });

    test('GetPets should return list of pets', () async {
      mockRepository._pets.add(tPet);
      final useCase = GetPets(mockRepository);
      final result = await useCase(const NoParams());
      expect(result.getOrElse(() => []).length, 1);
    });

    test('GetPetById should return matching pet', () async {
      mockRepository._pets.add(tPet);
      final useCase = GetPetById(mockRepository);
      final result = await useCase('pet-1');
      expect(result.getOrElse(() => null)?.name, 'Max');
    });

    test('UpdatePet should modify pet details', () async {
      mockRepository._pets.add(tPet);
      final useCase = UpdatePet(mockRepository);
      final updated = tPet.copyWith(name: 'Maximus');
      await useCase(updated);
      expect(mockRepository._pets.first.name, 'Maximus');
    });

    test('DeletePet should remove pet', () async {
      mockRepository._pets.add(tPet);
      final useCase = DeletePet(mockRepository);
      await useCase('pet-1');
      expect(mockRepository._pets.isEmpty, isTrue);
    });

    test(
      'UpdatePetSettings and GetPetSettings should handle settings flow',
      () async {
        final updateSettings = UpdatePetSettings(mockRepository);
        final getSettings = GetPetSettings(mockRepository);

        const settings = PetSettings(petId: 'pet-1', aiHealthTracking: true);
        await updateSettings(settings);

        final result = await getSettings('pet-1');
        expect(result.getOrElse(() => null)?.aiHealthTracking, isTrue);
      },
    );
  });
}
