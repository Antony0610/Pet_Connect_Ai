import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_share.dart';

/// Data model for PetShare mapping to Supabase tables.
class PetShareModel extends PetShare {
  const PetShareModel({
    required super.id,
    required super.petId,
    required super.userId,
    required super.userEmail,
    required super.userName,
    required super.role,
    required super.permissionLevel,
    super.status = 'active',
    super.avatarUrl,
    required super.invitedAt,
  });

  factory PetShareModel.fromJson(Map<String, dynamic> json) {
    return PetShareModel(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? json['email'] as String? ?? '',
      userName: json['user_name'] as String? ?? json['full_name'] as String? ?? 'Caregiver',
      role: json['role'] as String? ?? 'Co-Owner',
      permissionLevel: json['permission_level'] as String? ?? 'Full Access',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      invitedAt: json['invited_at'] != null
          ? DateTime.tryParse(json['invited_at'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  factory PetShareModel.fromEntity(PetShare entity) {
    return PetShareModel(
      id: entity.id,
      petId: entity.petId,
      userId: entity.userId,
      userEmail: entity.userEmail,
      userName: entity.userName,
      role: entity.role,
      permissionLevel: entity.permissionLevel,
      status: entity.status,
      avatarUrl: entity.avatarUrl,
      invitedAt: entity.invitedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'pet_id': petId,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'role': role,
      'permission_level': permissionLevel,
      'status': status,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'invited_at': invitedAt.toIso8601String(),
    };
  }
}
