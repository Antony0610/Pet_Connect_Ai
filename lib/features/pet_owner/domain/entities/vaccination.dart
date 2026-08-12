import 'package:equatable/equatable.dart';

/// Vaccination log entity for a pet.
class Vaccination extends Equatable {
  const Vaccination({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.administeredDate,
    this.nextDueDate,
    this.administeredBy,
    this.batchNumber,
    this.certificateUrl,
    this.notes,
    this.isCompleted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String vaccineName;
  final DateTime administeredDate;
  final DateTime? nextDueDate;
  final String? administeredBy;
  final String? batchNumber;
  final String? certificateUrl;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        petId,
        vaccineName,
        administeredDate,
        nextDueDate,
        administeredBy,
        batchNumber,
        certificateUrl,
        notes,
        isCompleted,
        createdAt,
        updatedAt,
      ];
}
