import 'package:petconnect_ai/features/administrator/domain/entities/staff_member.dart';

/// Data model for StaffMember mapping to Supabase tables.
class StaffMemberModel extends StaffMember {
  const StaffMemberModel({
    required super.id,
    required super.name,
    required super.title,
    required super.department,
    required super.shift,
    super.status = 'Available',
    super.phone,
    super.email,
    required super.createdAt,
  });

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'Staff Member',
      title: json['title'] as String? ?? json['role'] as String? ?? 'Specialist',
      department: json['department'] as String? ?? 'General Practice',
      shift: json['shift'] as String? ?? 'Today: 08:00 - 16:00',
      status: json['status'] as String? ?? 'Available',
      phone: json['phone'] as String? ?? json['contact_phone'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory StaffMemberModel.fromEntity(StaffMember entity) {
    return StaffMemberModel(
      id: entity.id,
      name: entity.name,
      title: entity.title,
      department: entity.department,
      shift: entity.shift,
      status: entity.status,
      phone: entity.phone,
      email: entity.email,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'title': title,
      'department': department,
      'shift': shift,
      'status': status,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
