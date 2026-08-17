import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/administrator/data/models/admin_user_entry_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/audit_log_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_report_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_setting_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/security_posture_summary_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AdminRemoteDataSource {
  Future<List<AuditLogModel>> getAuditLogs();
  Future<AuditLogModel> createAuditLog(AuditLogModel entry);

  Future<List<PlatformSettingModel>> getPlatformSettings();
  Future<PlatformSettingModel> updatePlatformSetting(
    String settingId,
    Map<String, dynamic> value,
  );
  Future<PlatformSettingModel> updatePlatformSettingByKey(
    String settingKey,
    Map<String, dynamic> value,
  );

  Future<List<AdminUserEntryModel>> getAdminUserDirectory();
  Future<AdminUserEntryModel> updateUserRole(String userId, String newRole);

  // Phase 11 — Analytics
  Future<PlatformReportSummaryModel?> getPlatformReports();

  // Phase 12 — Security Hardening
  Future<SecurityPostureSummaryModel> getSecurityPosture();
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AuditLogModel>> getAuditLogs() async {
    try {
      final response = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(200);

      return (response as List)
          .map((json) => AuditLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch audit logs: $e');
    }
  }

  @override
  Future<AuditLogModel> createAuditLog(AuditLogModel entry) async {
    try {
      final json = entry.toJson();
      final response = await _client
          .from('audit_logs')
          .insert(json)
          .select()
          .single();
      return AuditLogModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create audit log: $e');
    }
  }

  @override
  Future<List<PlatformSettingModel>> getPlatformSettings() async {
    try {
      final response = await _client
          .from('platform_settings')
          .select()
          .order('setting_key');

      return (response as List)
          .map(
            (json) =>
                PlatformSettingModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch platform settings: $e');
    }
  }

  @override
  Future<PlatformSettingModel> updatePlatformSetting(
    String settingId,
    Map<String, dynamic> value,
  ) async {
    try {
      final response = await _client
          .from('platform_settings')
          .update({
            'setting_value': value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', settingId)
          .select()
          .single();
      return PlatformSettingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update platform setting: $e');
    }
  }

  @override
  Future<PlatformSettingModel> updatePlatformSettingByKey(
    String settingKey,
    Map<String, dynamic> value,
  ) async {
    try {
      final response = await _client
          .from('platform_settings')
          .update({
            'setting_value': value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('setting_key', settingKey)
          .select()
          .single();
      return PlatformSettingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update platform setting by key: $e');
    }
  }

  @override
  Future<List<AdminUserEntryModel>> getAdminUserDirectory() async {
    try {
      final response = await _client
          .from('vw_admin_user_directory')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                AdminUserEntryModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch user directory: $e');
    }
  }

  @override
  Future<AdminUserEntryModel> updateUserRole(
    String userId,
    String newRole,
  ) async {
    try {
      final response = await _client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId)
          .select()
          .single();
      return AdminUserEntryModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update user role: $e');
    }
  }

  // Phase 11 — Analytics
  @override
  Future<PlatformReportSummaryModel?> getPlatformReports() async {
    try {
      final response = await _client
          .from('vw_platform_reports')
          .select()
          .maybeSingle();

      if (response == null) return null;
      return PlatformReportSummaryModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch platform reports: $e');
    }
  }

  // Phase 12 — Security Hardening
  @override
  Future<SecurityPostureSummaryModel> getSecurityPosture() async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'get_security_posture_summary',
      );
      return SecurityPostureSummaryModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch security posture summary: $e');
    }
  }
}
