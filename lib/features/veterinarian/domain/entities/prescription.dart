import 'package:equatable/equatable.dart';

/// Digital Prescription entity.
class Prescription extends Equatable {
  const Prescription({
    required this.id,
    required this.consultationId,
    required this.rxNumber,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.status = 'Active',
    required this.createdAt,
  });

  final String id;
  final String consultationId;
  final String rxNumber;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final String status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    consultationId,
    rxNumber,
    medicationName,
    dosage,
    frequency,
    duration,
    instructions,
    status,
    createdAt,
  ];
}
