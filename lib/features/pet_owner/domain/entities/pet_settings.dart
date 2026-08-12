import 'package:petconnect_ai/shared/domain/entity.dart';

/// PetSettings domain entity representing preferences in `pet_settings` table.
class PetSettings extends Entity {
  const PetSettings({
    required this.petId,
    this.aiHealthTracking = true,
    this.locationSharing = false,
    this.activityAlerts = true,
  });

  final String petId;
  final bool aiHealthTracking;
  final bool locationSharing;
  final bool activityAlerts;

  PetSettings copyWith({
    String? petId,
    bool? aiHealthTracking,
    bool? locationSharing,
    bool? activityAlerts,
  }) {
    return PetSettings(
      petId: petId ?? this.petId,
      aiHealthTracking: aiHealthTracking ?? this.aiHealthTracking,
      locationSharing: locationSharing ?? this.locationSharing,
      activityAlerts: activityAlerts ?? this.activityAlerts,
    );
  }

  @override
  List<Object?> get props => [
    petId,
    aiHealthTracking,
    locationSharing,
    activityAlerts,
  ];
}
