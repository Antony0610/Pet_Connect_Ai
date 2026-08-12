import 'package:equatable/equatable.dart';

/// Platform setting key-value entity managed by administrators.
class PlatformSetting extends Equatable {
  const PlatformSetting({
    required this.id,
    required this.settingKey,
    required this.settingValue,
    this.description,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String settingKey;
  final Map<String, dynamic> settingValue;
  final String? description;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        settingKey,
        settingValue,
        description,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}
