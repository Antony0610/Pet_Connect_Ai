import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/shared/data/model.dart';

/// Data model (DTO) mapping between database JSON and [UserProfile] entity.
class UserProfileModel implements Model {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final AppPortal role;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Creates a model from Supabase `profiles` table JSON map.
  factory UserProfileModel.fromJson(Json json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: AppPortalExtension.fromDbRole(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Maps this DTO to domain entity.
  UserProfile toEntity() => UserProfile(
        id: id,
        email: email,
        fullName: fullName,
        role: role,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Creates a DTO model from domain entity.
  factory UserProfileModel.fromEntity(UserProfile profile) => UserProfileModel(
        id: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        role: profile.role,
        avatarUrl: profile.avatarUrl,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );

  @override
  Json toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.toDbRole(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}
