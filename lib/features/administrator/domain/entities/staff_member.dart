import 'package:equatable/equatable.dart';

/// Staff member entity for VetOps and Administrator personnel management.
class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.shift,
    this.status = 'Available',
    this.phone,
    this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String title;
  final String department;
  final String shift;
  final String status;
  final String? phone;
  final String? email;
  final DateTime createdAt;

  StaffMember copyWith({
    String? id,
    String? name,
    String? title,
    String? department,
    String? shift,
    String? status,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      department: department ?? this.department,
      shift: shift ?? this.shift,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        title,
        department,
        shift,
        status,
        phone,
        email,
        createdAt,
      ];
}
