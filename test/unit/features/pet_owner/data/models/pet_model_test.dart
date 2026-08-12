import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';

void main() {
  const tPetModel = PetModel(
    id: 'pet-123',
    ownerId: 'user-456',
    name: 'Luna',
    species: 'dog',
    breed: 'Siberian Husky',
    gender: 'female',
    weightKg: 22.5,
    healthStatus: 'optimal',
  );

  const tPetJson = {
    'id': 'pet-123',
    'owner_id': 'user-456',
    'name': 'Luna',
    'species': 'dog',
    'breed': 'Siberian Husky',
    'gender': 'female',
    'weight_kg': 22.5,
    'health_status': 'optimal',
  };

  group('PetModel', () {
    test('should parse valid JSON into PetModel DTO', () {
      final result = PetModel.fromJson(tPetJson);
      expect(result.id, 'pet-123');
      expect(result.ownerId, 'user-456');
      expect(result.name, 'Luna');
      expect(result.species, 'dog');
      expect(result.breed, 'Siberian Husky');
      expect(result.gender, 'female');
      expect(result.weightKg, 22.5);
      expect(result.healthStatus, 'optimal');
    });

    test('should convert PetModel to valid JSON', () {
      final jsonMap = tPetModel.toJson();
      expect(jsonMap['id'], 'pet-123');
      expect(jsonMap['owner_id'], 'user-456');
      expect(jsonMap['name'], 'Luna');
      expect(jsonMap['species'], 'dog');
      expect(jsonMap['breed'], 'Siberian Husky');
      expect(jsonMap['weight_kg'], 22.5);
    });

    test('should convert to and from Pet domain entity', () {
      final entity = tPetModel.toEntity();
      expect(entity, isA<Pet>());
      expect(entity.id, 'pet-123');
      expect(entity.breedLine, 'Siberian Husky');

      final fromEntity = PetModel.fromEntity(entity);
      expect(fromEntity.id, 'pet-123');
      expect(fromEntity.name, 'Luna');
    });
  });
}
