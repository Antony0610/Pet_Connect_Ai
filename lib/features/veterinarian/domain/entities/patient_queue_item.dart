import 'package:equatable/equatable.dart';

/// Patient Queue View entity (derived from `public.vw_patient_queue`).
class PatientQueueItem extends Equatable {
  const PatientQueueItem({
    required this.queueId,
    required this.appointmentId,
    required this.petId,
    required this.petName,
    required this.breedAge,
    required this.priority,
    required this.reason,
    required this.appointmentDate,
    required this.status,
    required this.veterinarianId,
    required this.clinicId,
    required this.ownerName,
    required this.createdAt,
  });

  final String queueId;
  final String appointmentId;
  final String petId;
  final String petName;
  final String breedAge;
  final String priority;
  final String reason;
  final DateTime appointmentDate;
  final String status;
  final String veterinarianId;
  final String clinicId;
  final String ownerName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        queueId,
        appointmentId,
        petId,
        petName,
        breedAge,
        priority,
        reason,
        appointmentDate,
        status,
        veterinarianId,
        clinicId,
        ownerName,
        createdAt,
      ];
}
