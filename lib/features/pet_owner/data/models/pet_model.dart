import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/shared/data/model.dart';

/// Data model (DTO) mapping between database JSON and [Pet] domain entity.
class PetModel implements Model {
  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.species = 'dog',
    this.breed,
    this.gender = 'unknown',
    this.dateOfBirth,
    this.weightKg,
    this.microchipId,
    this.imageUrl,
    this.healthStatus = 'optimal',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? microchipId;
  final String? imageUrl;
  final String healthStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PetModel.fromJson(Json json) {
    return PetModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? 'dog',
      breed: json['breed'] as String?,
      gender: json['gender'] as String? ?? 'unknown',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      weightKg: json['weight_kg'] != null
          ? (json['weight_kg'] as num).toDouble()
          : null,
      microchipId: json['microchip_id'] as String?,
      imageUrl: json['image_url'] as String?,
      healthStatus: json['health_status'] as String? ?? 'optimal',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Pet toEntity() => Pet(
    id: id,
    ownerId: ownerId,
    name: name,
    species: species,
    breed: breed,
    gender: gender,
    dateOfBirth: dateOfBirth,
    weightKg: weightKg,
    microchipId: microchipId,
    imageUrl: imageUrl,
    healthStatus: healthStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory PetModel.fromEntity(Pet pet) => PetModel(
    id: pet.id,
    ownerId: pet.ownerId,
    name: pet.name,
    species: pet.species,
    breed: pet.breed,
    gender: pet.gender,
    dateOfBirth: pet.dateOfBirth,
    weightKg: pet.weightKg,
    microchipId: pet.microchipId,
    imageUrl: pet.imageUrl,
    healthStatus: pet.healthStatus,
    createdAt: pet.createdAt,
    updatedAt: pet.updatedAt,
  );

  @override
  Json toJson() => {
    if (id.isNotEmpty) 'id': id,
    'owner_id': ownerId,
    'name': name,
    'species': species,
    if (breed != null) 'breed': breed,
    if (gender != null) 'gender': gender,
    if (dateOfBirth != null)
      'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
    if (weightKg != null) 'weight_kg': weightKg,
    if (microchipId != null) 'microchip_id': microchipId,
    if (imageUrl != null) 'image_url': imageUrl,
    'health_status': healthStatus,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
