import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';

class GeofenceModel extends Geofence {
  const GeofenceModel({
    required super.id,
    super.petId,
    required super.ownerId,
    super.name = 'Home Safe Zone',
    required super.centerLatitude,
    required super.centerLongitude,
    super.radiusMeters = 100.0,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String?,
      ownerId: json['owner_id'] as String,
      name: (json['name'] as String?) ?? 'Home Safe Zone',
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'owner_id': ownerId,
      'name': name,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
    };
  }
}
