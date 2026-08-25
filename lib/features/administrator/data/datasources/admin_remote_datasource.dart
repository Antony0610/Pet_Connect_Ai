import 'package:petconnect_ai/core/error/exceptions.dart' hide AuthException;
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
  Future<void> suspendUser(String userId, bool isSuspended);
  Future<void> resetUserPassword(String email);
  Future<void> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String password,
  });

  // Moderation
  Future<List<Map<String, dynamic>>> getFlaggedContent();
  Future<void> moderateContent({
    required String contentId,
    required String contentType,
    required String action,
  });

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

  @override
  Future<void> suspendUser(String userId, bool isSuspended) async {
    try {
      await _client.from('profiles').update({
        'is_suspended': isSuspended,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update account status: $e');
    }
  }

  @override
  Future<void> resetUserPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to provision account: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFlaggedContent() async {
    try {
      final posts = await _client
          .from('community_posts')
          .select('id, title, content, category, author_id, is_flagged, created_at')
          .eq('is_flagged', true)
          .order('created_at', ascending: false);

      final postList = posts as List<dynamic>;
      return postList.map((dynamic item) {
        final p = item as Map<String, dynamic>;
        final authorId = p['author_id']?.toString();
        final createdAt = p['created_at']?.toString();
        final content = p['content']?.toString() ?? p['title']?.toString() ?? 'Flagged community post';
        return <String, dynamic>{
          'id': p['id']?.toString() ?? '',
          'author': authorId != null ? 'Author #${authorId.substring(0, authorId.length > 6 ? 6 : authorId.length)}' : 'Community Member',
          'time': createdAt != null ? DateTime.tryParse(createdAt)?.toLocal().toString().substring(0, 16) ?? 'Recently' : 'Recently',
          'reason': 'Flagged by Community Filter',
          'content': content,
          'priority': 'MEDIUM',
          'type': 'Post',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> moderateContent({
    required String contentId,
    required String contentType,
    required String action,
  }) async {
    try {
      if (action == 'approve') {
        await _client
            .from('community_posts')
            .update({'is_flagged': false})
            .eq('id', contentId);
      } else if (action == 'remove') {
        await _client
            .from('community_posts')
            .delete()
            .eq('id', contentId);
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to execute moderation action: $e');
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
