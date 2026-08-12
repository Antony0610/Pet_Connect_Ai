import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';

class ConsultationModel extends Consultation {
  const ConsultationModel({
    required super.id,
    required super.appointmentId,
    required super.petId,
    required super.veterinarianId,
    super.subjective,
    super.objective,
    super.assessment,
    super.plan,
    required super.consultationDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      petId: json['pet_id'] as String,
      veterinarianId: json['veterinarian_id'] as String,
      subjective: json['subjective'] as String?,
      objective: json['objective'] as String?,
      assessment: json['assessment'] as String?,
      plan: json['plan'] as String?,
      consultationDate: DateTime.parse(json['consultation_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'pet_id': petId,
      'veterinarian_id': veterinarianId,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'consultation_date': consultationDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
