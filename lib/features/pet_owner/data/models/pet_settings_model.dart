import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/shared/data/model.dart';

/// Data model (DTO) mapping between database JSON and [PetSettings] entity.
class PetSettingsModel implements Model {
  const PetSettingsModel({
    required this.petId,
    this.aiHealthTracking = true,
    this.locationSharing = false,
    this.activityAlerts = true,
  });

  final String petId;
  final bool aiHealthTracking;
  final bool locationSharing;
  final bool activityAlerts;

  factory PetSettingsModel.fromJson(Json json) {
    return PetSettingsModel(
      petId: json['pet_id'] as String,
      aiHealthTracking: json['ai_health_tracking'] as bool? ?? true,
      locationSharing: json['location_sharing'] as bool? ?? false,
      activityAlerts: json['activity_alerts'] as bool? ?? true,
    );
  }

  PetSettings toEntity() => PetSettings(
    petId: petId,
    aiHealthTracking: aiHealthTracking,
    locationSharing: locationSharing,
    activityAlerts: activityAlerts,
  );

  factory PetSettingsModel.fromEntity(PetSettings settings) => PetSettingsModel(
    petId: settings.petId,
    aiHealthTracking: settings.aiHealthTracking,
    locationSharing: settings.locationSharing,
    activityAlerts: settings.activityAlerts,
  );

  @override
  Json toJson() => {
    'pet_id': petId,
    'ai_health_tracking': aiHealthTracking,
    'location_sharing': locationSharing,
    'activity_alerts': activityAlerts,
  };
}
