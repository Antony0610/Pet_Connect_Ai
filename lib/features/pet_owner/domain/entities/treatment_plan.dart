import 'package:equatable/equatable.dart';

/// Active recovery/treatment plan entity.
class TreatmentPlan extends Equatable {
  const TreatmentPlan({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    this.targetDate,
    required this.progressPercent,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String title;
  final String category;
  final DateTime? targetDate;
  final int progressPercent;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    title,
    category,
    targetDate,
    progressPercent,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
}
