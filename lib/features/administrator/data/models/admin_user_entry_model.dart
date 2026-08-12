import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';

class AdminUserEntryModel extends AdminUserEntry {
  const AdminUserEntryModel({
    required super.id,
    required super.fullName,
    super.email,
    required super.role,
    super.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminUserEntryModel.fromJson(Map<String, dynamic> json) {
    return AdminUserEntryModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Unknown',
      email: json['email'] as String?,
      role: (json['role'] as String?) ?? 'pet_owner',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
