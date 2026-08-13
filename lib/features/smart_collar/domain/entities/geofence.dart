import 'package:equatable/equatable.dart';

/// Represents a safety geofence zone.
class Geofence extends Equatable {
  const Geofence({
    required this.id,
    this.petId,
    required this.ownerId,
    this.name = 'Home Safe Zone',
    required this.centerLatitude,
    required this.centerLongitude,
    this.radiusMeters = 100.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? petId;
  final String ownerId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    ownerId,
    name,
    centerLatitude,
    centerLongitude,
    radiusMeters,
    isActive,
    createdAt,
    updatedAt,
  ];
}
