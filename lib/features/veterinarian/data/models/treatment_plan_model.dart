import 'package:petconnect_ai/features/veterinarian/domain/entities/treatment_plan.dart';

class TreatmentPlanModel extends TreatmentPlan {
  const TreatmentPlanModel({
    required super.id,
    required super.petId,
    required super.title,
    required super.category,
    super.targetDate,
    super.progressPercent = 0,
    super.status = 'active',
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPlanModel(
      id: json['id'] as String,
      petId: json['petId'] as String? ?? json['pet_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'] as String)
          : null,
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory TreatmentPlanModel.fromEntity(TreatmentPlan entity) {
    return TreatmentPlanModel(
      id: entity.id,
      petId: entity.petId,
      title: entity.title,
      category: entity.category,
      targetDate: entity.targetDate,
      progressPercent: entity.progressPercent,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'category': category,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T').first,
      'progress_percent': progressPercent,
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
