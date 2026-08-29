import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/volunteer_responder.dart';

class VolunteerResponderModel extends VolunteerResponder {
  const VolunteerResponderModel({
    required super.id,
    super.userId,
    required super.name,
    super.role = 'Tier 1 Responder',
    super.sector = 'Sector 1 (Central)',
    super.skills = const ['First Aid', 'K9 Handler'],
    super.phone,
    super.isOnDuty = true,
    super.totalRescues = 0,
    super.latitude,
    super.longitude,
    super.createdAt,
    super.updatedAt,
  });

  factory VolunteerResponderModel.fromJson(Map<String, dynamic> json) {
    return VolunteerResponderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'Tier 1 Responder',
      sector: json['sector'] as String? ?? 'Sector 1 (Central)',
      skills: json['skills'] != null
          ? List<String>.from(json['skills'] as List)
          : const ['First Aid', 'K9 Handler'],
      phone: json['phone'] as String?,
      isOnDuty: json['is_on_duty'] as bool? ?? true,
      totalRescues: (json['total_rescues'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory VolunteerResponderModel.fromEntity(VolunteerResponder entity) {
    return VolunteerResponderModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      role: entity.role,
      sector: entity.sector,
      skills: entity.skills,
      phone: entity.phone,
      isOnDuty: entity.isOnDuty,
      totalRescues: entity.totalRescues,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'role': role,
      'sector': sector,
      'skills': skills,
      if (phone != null) 'phone': phone,
      'is_on_duty': isOnDuty,
      'total_rescues': totalRescues,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
