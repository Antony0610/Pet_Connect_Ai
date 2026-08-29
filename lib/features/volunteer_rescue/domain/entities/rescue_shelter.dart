import 'package:petconnect_ai/shared/domain/entity.dart';

/// Represents an Emergency Operations Center (EOC) emergency shelter and refuge facility.
class RescueShelter extends Entity {
  const RescueShelter({
    required this.id,
    required this.name,
    this.address,
    this.contactPhone,
    this.capacityTotal = 50,
    this.capacityOccupied = 0,
    this.speciesAccepted = const ['canine', 'feline'],
    this.status = 'open',
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? address;
  final String? contactPhone;
  final int capacityTotal;
  final int capacityOccupied;
  final List<String> speciesAccepted;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get occupancyPercent {
    if (capacityTotal <= 0) return 0;
    return ((capacityOccupied / capacityTotal) * 100).clamp(0, 100).toInt();
  }

  int get availableBeds => (capacityTotal - capacityOccupied).clamp(0, capacityTotal);

  RescueShelter copyWith({
    String? id,
    String? name,
    String? address,
    String? contactPhone,
    int? capacityTotal,
    int? capacityOccupied,
    List<String>? speciesAccepted,
    String? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RescueShelter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      capacityTotal: capacityTotal ?? this.capacityTotal,
      capacityOccupied: capacityOccupied ?? this.capacityOccupied,
      speciesAccepted: speciesAccepted ?? this.speciesAccepted,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        contactPhone,
        capacityTotal,
        capacityOccupied,
        speciesAccepted,
        status,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
