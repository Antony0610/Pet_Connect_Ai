import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.petId,
    required super.clinicId,
    required super.veterinarianId,
    required super.appointmentDate,
    super.durationMinutes = 30,
    required super.reason,
    super.status = 'Scheduled',
    super.priority = 'ROUTINE',
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      clinicId: json['clinic_id'] as String,
      veterinarianId: json['veterinarian_id'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      reason: json['reason'] as String,
      status: (json['status'] as String?) ?? 'Scheduled',
      priority: (json['priority'] as String?) ?? 'ROUTINE',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'clinic_id': clinicId,
      'veterinarian_id': veterinarianId,
      'appointment_date': appointmentDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reason': reason,
      'status': status,
      'priority': priority,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
