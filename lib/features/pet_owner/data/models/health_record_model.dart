import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';

class HealthRecordModel extends HealthRecord {
  const HealthRecordModel({
    required super.id,
    required super.petId,
    required super.recordDate,
    required super.category,
    required super.title,
    super.notes,
    super.diagnosis,
    super.treatment,
    super.veterinarianName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      category: (json['category'] as String?) ?? 'General',
      title: json['title'] as String,
      notes: json['notes'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatment: json['treatment'] as String?,
      veterinarianName: json['veterinarian_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'record_date': recordDate.toIso8601String().split('T').first,
      'category': category,
      'title': title,
      'notes': notes,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'veterinarian_name': veterinarianName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
