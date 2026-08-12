import 'package:equatable/equatable.dart';

/// Lost Pet Sighting report entity.
class LostPetSighting extends Equatable {
  const LostPetSighting({
    required this.id,
    required this.alertId,
    required this.reporterId,
    required this.sightingLocation,
    this.latitude,
    this.longitude,
    required this.sightingTime,
    this.photoUrl,
    this.notes,
    this.status = 'UNVERIFIED',
    required this.createdAt,
  });

  final String id;
  final String alertId;
  final String reporterId;
  final String sightingLocation;
  final double? latitude;
  final double? longitude;
  final DateTime sightingTime;
  final String? photoUrl;
  final String? notes;
  final String status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    alertId,
    reporterId,
    sightingLocation,
    latitude,
    longitude,
    sightingTime,
    photoUrl,
    notes,
    status,
    createdAt,
  ];
}
