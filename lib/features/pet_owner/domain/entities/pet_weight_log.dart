import 'package:equatable/equatable.dart';

/// Historical pet weight measurement log entry.
class PetWeightLog extends Equatable {
  const PetWeightLog({
    required this.id,
    required this.petId,
    required this.recordedAt,
    required this.weightKg,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final DateTime recordedAt;
  final double weightKg;
  final String? notes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        petId,
        recordedAt,
        weightKg,
        notes,
        createdAt,
      ];
}
