import 'package:equatable/equatable.dart';

/// Entity representing a shared pet caregiver or co-owner relationship.
class PetShare extends Equatable {
  const PetShare({
    required this.id,
    required this.petId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.role,
    required this.permissionLevel,
    this.status = 'active',
    this.avatarUrl,
    required this.invitedAt,
  });

  final String id;
  final String petId;
  final String userId;
  final String userEmail;
  final String userName;
  final String role; // 'Co-Owner', 'Veterinarian', 'Pet Sitter', 'Family'
  final String permissionLevel; // 'Full Access', 'Medical Access', 'Edit Access', 'View Only'
  final String status; // 'active', 'pending', 'revoked'
  final String? avatarUrl;
  final DateTime invitedAt;

  PetShare copyWith({
    String? id,
    String? petId,
    String? userId,
    String? userEmail,
    String? userName,
    String? role,
    String? permissionLevel,
    String? status,
    String? avatarUrl,
    DateTime? invitedAt,
  }) {
    return PetShare(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      invitedAt: invitedAt ?? this.invitedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        petId,
        userId,
        userEmail,
        userName,
        role,
        permissionLevel,
        status,
        avatarUrl,
        invitedAt,
      ];
}
