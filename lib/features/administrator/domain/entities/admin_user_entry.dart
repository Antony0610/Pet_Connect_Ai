import 'package:equatable/equatable.dart';

/// Admin user directory entry (read-only view projection from profiles).
class AdminUserEntry extends Equatable {
  const AdminUserEntry({
    required this.id,
    required this.fullName,
    this.email,
    required this.role,
    this.avatarUrl,
    this.isSuspended = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String role;
  final String? avatarUrl;
  final bool isSuspended;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    role,
    avatarUrl,
    isSuspended,
    createdAt,
    updatedAt,
  ];
}
