import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';

class TreatmentPlanModel extends TreatmentPlan {
  const TreatmentPlanModel({
    required super.id,
    required super.petId,
    required super.title,
    required super.category,
    super.targetDate,
    required super.progressPercent,
    required super.status,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPlanModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String,
      category: (json['category'] as String?) ?? 'Rehab',
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'category': category,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'progress_percent': progressPercent,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
