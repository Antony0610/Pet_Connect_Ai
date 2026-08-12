import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';

class PatientQueueItemModel extends PatientQueueItem {
  const PatientQueueItemModel({
    required super.queueId,
    required super.appointmentId,
    required super.petId,
    required super.petName,
    required super.breedAge,
    required super.priority,
    required super.reason,
    required super.appointmentDate,
    required super.status,
    required super.veterinarianId,
    required super.clinicId,
    required super.ownerName,
    required super.createdAt,
  });

  factory PatientQueueItemModel.fromJson(Map<String, dynamic> json) {
    return PatientQueueItemModel(
      queueId: json['queue_id'] as String,
      appointmentId: json['appointment_id'] as String,
      petId: json['pet_id'] as String,
      petName: json['pet_name'] as String,
      breedAge: json['breed_age'] as String,
      priority: (json['priority'] as String?) ?? 'ROUTINE',
      reason: json['reason'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      status: json['status'] as String,
      veterinarianId: json['veterinarian_id'] as String,
      clinicId: json['clinic_id'] as String,
      ownerName: json['owner_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queue_id': queueId,
      'appointment_id': appointmentId,
      'pet_id': petId,
      'pet_name': petName,
      'breed_age': breedAge,
      'priority': priority,
      'reason': reason,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      'veterinarian_id': veterinarianId,
      'clinic_id': clinicId,
      'owner_name': ownerName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
