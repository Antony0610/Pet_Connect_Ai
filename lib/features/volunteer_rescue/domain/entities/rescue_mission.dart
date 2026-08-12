import 'package:equatable/equatable.dart';

/// Operational Rescue Mission entity.
class RescueMission extends Equatable {
  const RescueMission({
    required this.id,
    required this.alertId,
    this.leadVolunteerId,
    required this.missionTitle,
    this.priority = 'HIGH',
    this.status = 'DISPATCHED',
    this.searchRadiusMeters = 500,
    this.notes,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String alertId;
  final String? leadVolunteerId;
  final String missionTitle;
  final String priority;
  final String status;
  final int searchRadiusMeters;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    alertId,
    leadVolunteerId,
    missionTitle,
    priority,
    status,
    searchRadiusMeters,
    notes,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
