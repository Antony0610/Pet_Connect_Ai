import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';

class VaccinationModel extends Vaccination {
  const VaccinationModel({
    required super.id,
    required super.petId,
    required super.vaccineName,
    required super.administeredDate,
    super.nextDueDate,
    super.administeredBy,
    super.batchNumber,
    super.certificateUrl,
    super.notes,
    super.isCompleted = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      vaccineName: json['vaccine_name'] as String,
      administeredDate: DateTime.parse(json['administered_date'] as String),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      administeredBy: json['administered_by'] as String?,
      batchNumber: json['batch_number'] as String?,
      certificateUrl: json['certificate_url'] as String?,
      notes: json['notes'] as String?,
      isCompleted: (json['is_completed'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'vaccine_name': vaccineName,
      'administered_date': administeredDate.toIso8601String().split('T').first,
      'next_due_date': nextDueDate?.toIso8601String().split('T').first,
      'administered_by': administeredBy,
      'batch_number': batchNumber,
      'certificate_url': certificateUrl,
      'notes': notes,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
