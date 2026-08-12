import 'package:equatable/equatable.dart';

/// Clinical Consultation (SOAP) entity.
class Consultation extends Equatable {
  const Consultation({
    required this.id,
    required this.appointmentId,
    required this.petId,
    required this.veterinarianId,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    required this.consultationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String appointmentId;
  final String petId;
  final String veterinarianId;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final DateTime consultationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    appointmentId,
    petId,
    veterinarianId,
    subjective,
    objective,
    assessment,
    plan,
    consultationDate,
    createdAt,
    updatedAt,
  ];
}
