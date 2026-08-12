import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/pet_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_settings_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/repositories/pet_repository_impl.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';

class MockPetRemoteDataSource implements PetRemoteDataSource {
  final List<PetModel> _pets = [];
  final Map<String, PetSettingsModel> _settings = {};
  bool shouldThrowServerException = false;
  bool shouldThrowAuthException = false;

  @override
  Future<List<PetModel>> getPets() async {
    _checkErrors();
    return _pets;
  }

  @override
  Future<PetModel?> getPetById(String id) async {
    _checkErrors();
    return _pets.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<PetModel> createPet(PetModel pet) async {
    _checkErrors();
    final created = PetModel(
      id: pet.id.isEmpty ? 'generated-id' : pet.id,
      ownerId: 'owner-123',
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      gender: pet.gender,
      weightKg: pet.weightKg,
      healthStatus: pet.healthStatus,
    );
    _pets.add(created);
    return created;
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    _checkErrors();
    _pets.removeWhere((p) => p.id == pet.id);
    _pets.add(pet);
    return pet;
  }

  @override
  Future<void> deletePet(String id) async {
    _checkErrors();
    _pets.removeWhere((p) => p.id == id);
  }

  @override
  Future<PetSettingsModel?> getPetSettings(String petId) async {
    _checkErrors();
    return _settings[petId];
  }

  @override
  Future<void> updatePetSettings(PetSettingsModel settings) async {
    _checkErrors();
    _settings[settings.petId] = settings;
  }

  void _checkErrors() {
    if (shouldThrowAuthException) {
      throw const AuthException('User unauthenticated');
    }
    if (shouldThrowServerException) {
      throw const ServerException('Database query failed');
    }
  }
}

void main() {
  late MockPetRemoteDataSource mockRemoteDataSource;
  late PetRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockPetRemoteDataSource();
    repository = PetRepositoryImpl(mockRemoteDataSource);
  });

  group('PetRepositoryImpl', () {
    const tPet = Pet(
      id: 'pet-1',
      ownerId: 'owner-123',
      name: 'Buddy',
      species: 'dog',
      breed: 'Golden Retriever',
    );

    test('should create and retrieve pets successfully', () async {
      final createResult = await repository.createPet(tPet);
      expect(createResult.isRight(), isTrue);

      final getPetsResult = await repository.getPets();
      expect(getPetsResult.isRight(), isTrue);
      final pets = getPetsResult.getOrElse(() => []);
      expect(pets.length, 1);
      expect(pets.first.name, 'Buddy');
    });

    test('should retrieve pet by id', () async {
      await repository.createPet(tPet);
      final result = await repository.getPetById('pet-1');
      expect(result.isRight(), isTrue);
      final pet = result.getOrElse(() => null);
      expect(pet?.name, 'Buddy');
    });

    test('should update existing pet', () async {
      await repository.createPet(tPet);
      final updated = tPet.copyWith(name: 'Buddy Golden');
      final updateResult = await repository.updatePet(updated);
      expect(updateResult.isRight(), isTrue);

      final petResult = await repository.getPetById('pet-1');
      expect(petResult.getOrElse(() => null)?.name, 'Buddy Golden');
    });

    test('should delete pet successfully', () async {
      await repository.createPet(tPet);
      final deleteResult = await repository.deletePet('pet-1');
      expect(deleteResult.isRight(), isTrue);

      final getPetsResult = await repository.getPets();
      expect(getPetsResult.getOrElse(() => []).isEmpty, isTrue);
    });

    test('should manage pet settings', () async {
      const settings = PetSettings(
        petId: 'pet-1',
        aiHealthTracking: true,
        locationSharing: true,
      );

      final updateSettingsResult = await repository.updatePetSettings(settings);
      expect(updateSettingsResult.isRight(), isTrue);

      final getSettingsResult = await repository.getPetSettings('pet-1');
      expect(getSettingsResult.isRight(), isTrue);
      expect(getSettingsResult.getOrElse(() => null)?.locationSharing, isTrue);
    });

    test('should return ServerFailure on database exception', () async {
      mockRemoteDataSource.shouldThrowServerException = true;
      final result = await repository.getPets();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should have returned ServerFailure'),
      );
    });

    test('should return AuthFailure on unauthenticated exception', () async {
      mockRemoteDataSource.shouldThrowAuthException = true;
      final result = await repository.getPets();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Should have returned AuthFailure'),
      );
    });
  });
}
