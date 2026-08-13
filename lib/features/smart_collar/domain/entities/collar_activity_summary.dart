import 'package:equatable/equatable.dart';

/// Represents daily accelerometer & activity metrics.
class CollarActivitySummary extends Equatable {
  const CollarActivitySummary({
    required this.id,
    required this.collarId,
    this.petId,
    required this.activityDate,
    this.activeMinutes = 0,
    this.restMinutes = 0,
    this.stepCount = 0,
    this.caloriesBurned = 0,
    required this.createdAt,
  });

  final String id;
  final String collarId;
  final String? petId;
  final DateTime activityDate;
  final int activeMinutes;
  final int restMinutes;
  final int stepCount;
  final int caloriesBurned;

  @override
  List<Object?> get props => [
    id,
    collarId,
    petId,
    activityDate,
    activeMinutes,
    restMinutes,
    stepCount,
    caloriesBurned,
    createdAt,
  ];
}
