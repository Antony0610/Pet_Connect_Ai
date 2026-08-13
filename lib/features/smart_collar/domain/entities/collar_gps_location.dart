import 'package:equatable/equatable.dart';

/// Represents a GPS telemetry datapoint transmitted by a Smart Collar.
class CollarGpsLocation extends Equatable {
  const CollarGpsLocation({
    required this.id,
    required this.collarId,
    this.petId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.gpsTimestamp,
    required this.serverTimestamp,
    this.isOfflineTelemetry = false,
    required this.createdAt,
  });

  final String id;
  final String collarId;
  final String? petId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime gpsTimestamp;
  final DateTime serverTimestamp;
  final bool isOfflineTelemetry;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    collarId,
    petId,
    latitude,
    longitude,
    accuracy,
    altitude,
    speed,
    heading,
    gpsTimestamp,
    serverTimestamp,
    isOfflineTelemetry,
    createdAt,
  ];
}
