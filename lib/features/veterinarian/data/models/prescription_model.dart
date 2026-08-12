import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';

class PrescriptionModel extends Prescription {
  const PrescriptionModel({
    required super.id,
    required super.consultationId,
    required super.rxNumber,
    required super.medicationName,
    required super.dosage,
    required super.frequency,
    required super.duration,
    super.instructions,
    super.status = 'Active',
    required super.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String,
      consultationId: json['consultation_id'] as String,
      rxNumber: json['rx_number'] as String,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String,
      instructions: json['instructions'] as String?,
      status: (json['status'] as String?) ?? 'Active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'rx_number': rxNumber,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
