import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/shared/domain/entity.dart';

/// Helper extension to map between [AppPortal] and database role strings.
extension AppPortalExtension on AppPortal {
  String toDbRole() => switch (this) {
        AppPortal.petOwner => 'pet_owner',
        AppPortal.veterinarian => 'veterinarian',
        AppPortal.volunteerRescue => 'volunteer_rescue',
        AppPortal.administrator => 'administrator',
      };

  static AppPortal fromDbRole(String? roleStr) => switch (roleStr) {
        'veterinarian' => AppPortal.veterinarian,
        'volunteer_rescue' => AppPortal.volunteerRescue,
        'administrator' => AppPortal.administrator,
        _ => AppPortal.petOwner,
      };
}

/// User profile domain entity representing a record in the `profiles` table.
class UserProfile extends Entity {
  const UserProfile({
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

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    AppPortal? role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        avatarUrl,
        createdAt,
        updatedAt,
      ];
}
