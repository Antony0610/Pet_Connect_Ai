import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_settings_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';

void main() {
  const tSettingsModel = PetSettingsModel(
    petId: 'pet-123',
    aiHealthTracking: true,
    locationSharing: true,
    activityAlerts: false,
  );

  const tSettingsJson = {
    'pet_id': 'pet-123',
    'ai_health_tracking': true,
    'location_sharing': true,
    'activity_alerts': false,
  };

  group('PetSettingsModel', () {
    test('should parse valid JSON into PetSettingsModel DTO', () {
      final result = PetSettingsModel.fromJson(tSettingsJson);
      expect(result.petId, 'pet-123');
      expect(result.aiHealthTracking, isTrue);
      expect(result.locationSharing, isTrue);
      expect(result.activityAlerts, isFalse);
    });

    test('should convert PetSettingsModel to valid JSON', () {
      final jsonMap = tSettingsModel.toJson();
      expect(jsonMap['pet_id'], 'pet-123');
      expect(jsonMap['ai_health_tracking'], isTrue);
      expect(jsonMap['location_sharing'], isTrue);
      expect(jsonMap['activity_alerts'], isFalse);
    });

    test('should convert to and from PetSettings entity', () {
      final entity = tSettingsModel.toEntity();
      expect(entity, isA<PetSettings>());
      expect(entity.petId, 'pet-123');

      final fromEntity = PetSettingsModel.fromEntity(entity);
      expect(fromEntity.petId, 'pet-123');
      expect(fromEntity.locationSharing, isTrue);
    });
  });
}
