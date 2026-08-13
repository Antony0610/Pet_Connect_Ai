import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_activity_summary.dart';

class CollarActivitySummaryModel extends CollarActivitySummary {
  const CollarActivitySummaryModel({
    required super.id,
    required super.collarId,
    super.petId,
    required super.activityDate,
    super.activeMinutes = 0,
    super.restMinutes = 0,
    super.stepCount = 0,
    super.caloriesBurned = 0,
    required super.createdAt,
  });

  factory CollarActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return CollarActivitySummaryModel(
      id: json['id'] as String,
      collarId: json['collar_id'] as String,
      petId: json['pet_id'] as String?,
      activityDate: DateTime.parse(json['activity_date'] as String),
      activeMinutes: (json['active_minutes'] as int?) ?? 0,
      restMinutes: (json['rest_minutes'] as int?) ?? 0,
      stepCount: (json['step_count'] as int?) ?? 0,
      caloriesBurned: (json['calories_burned'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collar_id': collarId,
      'pet_id': petId,
      'activity_date': activityDate.toIso8601String().split('T').first,
      'active_minutes': activeMinutes,
      'rest_minutes': restMinutes,
      'step_count': stepCount,
      'calories_burned': caloriesBurned,
    };
  }
}
