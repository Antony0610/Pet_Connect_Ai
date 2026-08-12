import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';

class LostPetAlertModel extends LostPetAlert {
  const LostPetAlertModel({
    required super.id,
    required super.petId,
    required super.ownerId,
    super.alertStatus = 'ACTIVE',
    required super.lastSeenLocation,
    required super.latitude,
    required super.longitude,
    required super.lastSeenTime,
    super.description,
    super.contactPhone,
    super.rewardAmount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LostPetAlertModel.fromJson(Map<String, dynamic> json) {
    return LostPetAlertModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      ownerId: json['owner_id'] as String,
      alertStatus: (json['alert_status'] as String?) ?? 'ACTIVE',
      lastSeenLocation: json['last_seen_location'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastSeenTime: DateTime.parse(json['last_seen_time'] as String),
      description: json['description'] as String?,
      contactPhone: json['contact_phone'] as String?,
      rewardAmount: json['reward_amount'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'owner_id': ownerId,
      'alert_status': alertStatus,
      'last_seen_location': lastSeenLocation,
      'latitude': latitude,
      'longitude': longitude,
      'last_seen_time': lastSeenTime.toIso8601String(),
      'description': description,
      'contact_phone': contactPhone,
      'reward_amount': rewardAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
