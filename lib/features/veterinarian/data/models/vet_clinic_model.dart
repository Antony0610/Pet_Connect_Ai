import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';

class VetClinicModel extends VetClinic {
  const VetClinicModel({
    required super.id,
    required super.name,
    super.address,
    super.phone,
    super.email,
    super.licenseNumber,
    required super.ownerId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VetClinicModel.fromJson(Map<String, dynamic> json) {
    return VetClinicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      licenseNumber: json['license_number'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'license_number': licenseNumber,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
