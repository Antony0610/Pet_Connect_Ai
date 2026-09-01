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
    this.phone,
    this.city,
    this.latitude,
    this.longitude,
    this.bio,
    this.isSuspended = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final AppPortal role;
  final String? avatarUrl;
  final String? phone;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? bio;
  final bool isSuspended;
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
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      bio: json['bio'] as String?,
      isSuspended: (json['is_suspended'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Creates a copy of this model with updated values.
  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    AppPortal? role,
    String? avatarUrl,
    String? phone,
    String? city,
    double? latitude,
    double? longitude,
    String? bio,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bio: bio ?? this.bio,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Maps this DTO to domain entity.
  UserProfile toEntity() => UserProfile(
    id: id,
    email: email,
    fullName: fullName,
    role: role,
    avatarUrl: avatarUrl,
    phone: phone,
    city: city,
    latitude: latitude,
    longitude: longitude,
    bio: bio,
    isSuspended: isSuspended,
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
    phone: profile.phone,
    city: profile.city,
    latitude: profile.latitude,
    longitude: profile.longitude,
    bio: profile.bio,
    isSuspended: profile.isSuspended,
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
    'phone': phone,
    if (city != null) 'city': city,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (bio != null) 'bio': bio,
    'is_suspended': isSuspended,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
