import 'package:equatable/equatable.dart';

/// Clinical medical record entity for a pet.
class HealthRecord extends Equatable {
  const HealthRecord({
    required this.id,
    required this.petId,
    required this.recordDate,
    required this.category,
    required this.title,
    this.notes,
    this.diagnosis,
    this.treatment,
    this.veterinarianName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final DateTime recordDate;
  final String category;
  final String title;
  final String? notes;
  final String? diagnosis;
  final String? treatment;
  final String? veterinarianName;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    recordDate,
    category,
    title,
    notes,
    diagnosis,
    treatment,
    veterinarianName,
    createdAt,
    updatedAt,
  ];
}
