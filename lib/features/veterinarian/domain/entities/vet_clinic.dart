import 'package:equatable/equatable.dart';

/// Veterinary Clinic entity.
class VetClinic extends Equatable {
  const VetClinic({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.licenseNumber,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? licenseNumber;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        email,
        licenseNumber,
        ownerId,
        createdAt,
        updatedAt,
      ];
}
