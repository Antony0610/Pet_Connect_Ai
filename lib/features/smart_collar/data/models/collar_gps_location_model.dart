import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';

class CollarGpsLocationModel extends CollarGpsLocation {
  const CollarGpsLocationModel({
    required super.id,
    required super.collarId,
    super.petId,
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.altitude,
    super.speed,
    super.heading,
    required super.gpsTimestamp,
    required super.serverTimestamp,
    super.isOfflineTelemetry = false,
    required super.createdAt,
  });

  factory CollarGpsLocationModel.fromJson(Map<String, dynamic> json) {
    return CollarGpsLocationModel(
      id: json['id'] as String,
      collarId: json['collar_id'] as String,
      petId: json['pet_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      gpsTimestamp: DateTime.parse(json['gps_timestamp'] as String),
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
      isOfflineTelemetry: (json['is_offline_telemetry'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collar_id': collarId,
      'pet_id': petId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'gps_timestamp': gpsTimestamp.toIso8601String(),
      'is_offline_telemetry': isOfflineTelemetry,
    };
  }
}
