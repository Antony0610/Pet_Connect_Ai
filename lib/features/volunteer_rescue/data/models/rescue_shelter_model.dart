import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_shelter.dart';

class RescueShelterModel extends RescueShelter {
  const RescueShelterModel({
    required super.id,
    required super.name,
    super.address,
    super.contactPhone,
    super.capacityTotal = 50,
    super.capacityOccupied = 0,
    super.speciesAccepted = const ['canine', 'feline'],
    super.status = 'open',
    super.latitude,
    super.longitude,
    super.createdAt,
    super.updatedAt,
  });

  factory RescueShelterModel.fromJson(Map<String, dynamic> json) {
    return RescueShelterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      contactPhone: json['contact_phone'] as String?,
      capacityTotal: (json['capacity_total'] as num?)?.toInt() ?? 50,
      capacityOccupied: (json['capacity_occupied'] as num?)?.toInt() ?? 0,
      speciesAccepted: json['species_accepted'] != null
          ? List<String>.from(json['species_accepted'] as List)
          : const ['canine', 'feline'],
      status: json['status'] as String? ?? 'open',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory RescueShelterModel.fromEntity(RescueShelter entity) {
    return RescueShelterModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      contactPhone: entity.contactPhone,
      capacityTotal: entity.capacityTotal,
      capacityOccupied: entity.capacityOccupied,
      speciesAccepted: entity.speciesAccepted,
      status: entity.status,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (address != null) 'address': address,
      if (contactPhone != null) 'contact_phone': contactPhone,
      'capacity_total': capacityTotal,
      'capacity_occupied': capacityOccupied,
      'species_accepted': speciesAccepted,
      'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
