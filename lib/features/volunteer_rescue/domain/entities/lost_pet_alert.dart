import 'package:equatable/equatable.dart';

/// Lost Pet Alert entity.
class LostPetAlert extends Equatable {
  const LostPetAlert({
    required this.id,
    required this.petId,
    required this.ownerId,
    this.alertStatus = 'ACTIVE',
    required this.lastSeenLocation,
    required this.latitude,
    required this.longitude,
    required this.lastSeenTime,
    this.description,
    this.contactPhone,
    this.rewardAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String ownerId;
  final String alertStatus;
  final String lastSeenLocation;
  final double latitude;
  final double longitude;
  final DateTime lastSeenTime;
  final String? description;
  final String? contactPhone;
  final String? rewardAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    ownerId,
    alertStatus,
    lastSeenLocation,
    latitude,
    longitude,
    lastSeenTime,
    description,
    contactPhone,
    rewardAmount,
    createdAt,
    updatedAt,
  ];
}
