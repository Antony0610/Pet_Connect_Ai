import 'package:equatable/equatable.dart';

/// Veterinary Appointment entity.
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.veterinarianId,
    required this.appointmentDate,
    this.durationMinutes = 30,
    required this.reason,
    this.status = 'Scheduled',
    this.priority = 'ROUTINE',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String clinicId;
  final String veterinarianId;
  final DateTime appointmentDate;
  final int durationMinutes;
  final String reason;
  final String status;
  final String priority;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    clinicId,
    veterinarianId,
    appointmentDate,
    durationMinutes,
    reason,
    status,
    priority,
    notes,
    createdAt,
    updatedAt,
  ];
}
