import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';

class RescueMissionModel extends RescueMission {
  const RescueMissionModel({
    required super.id,
    required super.alertId,
    super.leadVolunteerId,
    required super.missionTitle,
    super.priority = 'HIGH',
    super.status = 'DISPATCHED',
    super.searchRadiusMeters = 500,
    super.notes,
    super.startedAt,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RescueMissionModel.fromJson(Map<String, dynamic> json) {
    return RescueMissionModel(
      id: json['id'] as String,
      alertId: json['alert_id'] as String,
      leadVolunteerId: json['lead_volunteer_id'] as String?,
      missionTitle: json['mission_title'] as String,
      priority: (json['priority'] as String?) ?? 'HIGH',
      status: (json['status'] as String?) ?? 'DISPATCHED',
      searchRadiusMeters:
          (json['search_radius_meters'] as num?)?.toInt() ?? 500,
      notes: json['notes'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_id': alertId,
      'lead_volunteer_id': leadVolunteerId,
      'mission_title': missionTitle,
      'priority': priority,
      'status': status,
      'search_radius_meters': searchRadiusMeters,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
