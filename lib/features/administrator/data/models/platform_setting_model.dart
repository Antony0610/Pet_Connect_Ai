import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';

class PlatformSettingModel extends PlatformSetting {
  const PlatformSettingModel({
    required super.id,
    required super.settingKey,
    required super.settingValue,
    super.description,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PlatformSettingModel.fromJson(Map<String, dynamic> json) {
    return PlatformSettingModel(
      id: json['id'] as String,
      settingKey: json['setting_key'] as String,
      settingValue: (json['setting_value'] as Map<String, dynamic>?) ?? {},
      description: json['description'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setting_key': settingKey,
      'setting_value': settingValue,
      'description': description,
      'updated_by': updatedBy,
    };
  }
}
