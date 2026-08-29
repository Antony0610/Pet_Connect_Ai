import 'package:petconnect_ai/shared/domain/entity.dart';

/// Represents a volunteer emergency responder in the volunteer network.
class VolunteerResponder extends Entity {
  const VolunteerResponder({
    required this.id,
    this.userId,
    required this.name,
    this.role = 'Tier 1 Responder',
    this.sector = 'Sector 1 (Central)',
    this.skills = const ['First Aid', 'K9 Handler'],
    this.phone,
    this.isOnDuty = true,
    this.totalRescues = 0,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String role;
  final String sector;
  final List<String> skills;
  final String? phone;
  final bool isOnDuty;
  final int totalRescues;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VolunteerResponder copyWith({
    String? id,
    String? userId,
    String? name,
    String? role,
    String? sector,
    List<String>? skills,
    String? phone,
    bool? isOnDuty,
    int? totalRescues,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VolunteerResponder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      sector: sector ?? this.sector,
      skills: skills ?? this.skills,
      phone: phone ?? this.phone,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      totalRescues: totalRescues ?? this.totalRescues,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        role,
        sector,
        skills,
        phone,
        isOnDuty,
        totalRescues,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
