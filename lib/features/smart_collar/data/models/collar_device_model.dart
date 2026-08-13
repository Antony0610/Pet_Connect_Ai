import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';

class CollarDeviceModel extends CollarDevice {
  const CollarDeviceModel({
    required super.id,
    required super.deviceId,
    super.petId,
    required super.ownerId,
    super.firmwareVersion = 'v1.0.0',
    super.batteryPercentage = 100,
    super.connectivityType = 'BLE',
    super.signalStrength = 100,
    super.isLostMode = false,
    super.isActive = true,
    required super.lastSeenAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CollarDeviceModel.fromJson(Map<String, dynamic> json) {
    return CollarDeviceModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      petId: json['pet_id'] as String?,
      ownerId: json['owner_id'] as String,
      firmwareVersion: (json['firmware_version'] as String?) ?? 'v1.0.0',
      batteryPercentage: (json['battery_percentage'] as int?) ?? 100,
      connectivityType: (json['connectivity_type'] as String?) ?? 'BLE',
      signalStrength: json['signal_strength'] as int?,
      isLostMode: (json['is_lost_mode'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'pet_id': petId,
      'owner_id': ownerId,
      'firmware_version': firmwareVersion,
      'battery_percentage': batteryPercentage,
      'connectivity_type': connectivityType,
      'signal_strength': signalStrength,
      'is_lost_mode': isLostMode,
      'is_active': isActive,
    };
  }
}
