import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';

class LostPetSightingModel extends LostPetSighting {
  const LostPetSightingModel({
    required super.id,
    required super.alertId,
    required super.reporterId,
    required super.sightingLocation,
    super.latitude,
    super.longitude,
    required super.sightingTime,
    super.photoUrl,
    super.notes,
    super.status = 'UNVERIFIED',
    required super.createdAt,
  });

  factory LostPetSightingModel.fromJson(Map<String, dynamic> json) {
    return LostPetSightingModel(
      id: json['id'] as String,
      alertId: json['alert_id'] as String,
      reporterId: json['reporter_id'] as String,
      sightingLocation: json['sighting_location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sightingTime: DateTime.parse(json['sighting_time'] as String),
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'UNVERIFIED',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_id': alertId,
      'reporter_id': reporterId,
      'sighting_location': sightingLocation,
      'latitude': latitude,
      'longitude': longitude,
      'sighting_time': sightingTime.toIso8601String(),
      'photo_url': photoUrl,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
