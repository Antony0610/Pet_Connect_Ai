import 'package:equatable/equatable.dart';

/// Represents a Smart Collar hardware device.
class CollarDevice extends Equatable {
  const CollarDevice({
    required this.id,
    required this.deviceId,
    this.petId,
    required this.ownerId,
    this.firmwareVersion = 'v1.0.0',
    this.batteryPercentage = 100,
    this.connectivityType = 'BLE',
    this.signalStrength = 100,
    this.isLostMode = false,
    this.isActive = true,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deviceId;
  final String? petId;
  final String ownerId;
  final String firmwareVersion;
  final int batteryPercentage;
  final String connectivityType; // BLE, WIFI, GSM_LTE
  final int? signalStrength;
  final bool isLostMode;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    deviceId,
    petId,
    ownerId,
    firmwareVersion,
    batteryPercentage,
    connectivityType,
    signalStrength,
    isLostMode,
    isActive,
    lastSeenAt,
    createdAt,
    updatedAt,
  ];
}
