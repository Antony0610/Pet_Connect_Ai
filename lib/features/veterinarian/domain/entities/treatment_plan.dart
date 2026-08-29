import 'package:petconnect_ai/shared/domain/entity.dart';

/// Represents a clinical treatment plan in the `treatment_plans` table.
class TreatmentPlan extends Entity {
  const TreatmentPlan({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    this.targetDate,
    this.progressPercent = 0,
    this.status = 'active',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String petId;
  final String title;
  final String category;
  final DateTime? targetDate;
  final int progressPercent;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TreatmentPlan copyWith({
    String? id,
    String? petId,
    String? title,
    String? category,
    DateTime? targetDate,
    int? progressPercent,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TreatmentPlan(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
