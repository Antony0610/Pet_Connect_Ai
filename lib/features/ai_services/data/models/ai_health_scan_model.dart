import 'package:petconnect_ai/features/ai_services/domain/entities/ai_health_scan.dart';

class AiHealthScanModel extends AiHealthScan {
  const AiHealthScanModel({
    required super.id,
    required super.userId,
    super.petId,
    required super.symptomDescription,
    super.imageUrl,
    required super.analysisSummary,
    super.urgencyLevel = 'ROUTINE',
    super.recommendations = const [],
    required super.createdAt,
  });

  factory AiHealthScanModel.fromJson(Map<String, dynamic> json) {
    return AiHealthScanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      symptomDescription: json['symptom_description'] as String,
      imageUrl: json['image_url'] as String?,
      analysisSummary:
          (json['analysis_summary'] as String?) ?? 'Analysis unavailable.',
      urgencyLevel: (json['urgency_level'] as String?) ?? 'ROUTINE',
      recommendations: (json['recommendations'] as List<dynamic>?) ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'pet_id': petId,
      'symptom_description': symptomDescription,
      'image_url': imageUrl,
      'analysis_summary': analysisSummary,
      'urgency_level': urgencyLevel,
      'recommendations': recommendations,
    };
  }
}
