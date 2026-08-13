import 'package:equatable/equatable.dart';

/// Represents a multimodal AI health symptom scan result.
class AiHealthScan extends Equatable {
  const AiHealthScan({
    required this.id,
    required this.userId,
    this.petId,
    required this.symptomDescription,
    this.imageUrl,
    required this.analysisSummary,
    this.urgencyLevel = 'ROUTINE',
    this.recommendations = const [],
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? petId;
  final String symptomDescription;
  final String? imageUrl;
  final String analysisSummary;
  final String urgencyLevel; // ROUTINE, MODERATE, CRITICAL
  final List<dynamic> recommendations;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    petId,
    symptomDescription,
    imageUrl,
    analysisSummary,
    urgencyLevel,
    recommendations,
    createdAt,
  ];
}
