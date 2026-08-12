import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';

class PetWeightLogModel extends PetWeightLog {
  const PetWeightLogModel({
    required super.id,
    required super.petId,
    required super.recordedAt,
    required super.weightKg,
    super.notes,
    required super.createdAt,
  });

  factory PetWeightLogModel.fromJson(Map<String, dynamic> json) {
    return PetWeightLogModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      weightKg: (json['weight_kg'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'recorded_at': recordedAt.toIso8601String(),
      'weight_kg': weightKg,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
