import 'package:petconnect_ai/core/error/exceptions.dart' hide AuthException;
import 'package:petconnect_ai/features/administrator/data/models/admin_article_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/admin_user_entry_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/audit_log_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_report_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_setting_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/security_posture_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/staff_member_model.dart';
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
  Future<void> deleteUser(String userId);
  Future<void> resetUserPassword(String email);
  Future<void> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String password,
  });

  // Staff Management
  Future<List<StaffMemberModel>> getStaffMembers();
  Future<StaffMemberModel> saveStaffMember(StaffMemberModel member);
  Future<void> deleteStaffMember(String id);

  // Content Management System (CMS)
  Future<List<AdminArticleModel>> getArticles({String? status});
  Future<AdminArticleModel> saveArticle(AdminArticleModel article);
  Future<void> deleteArticle(String id);

  // Live Database Table Assessment
  Future<Map<String, int>> getDatabaseTableCounts();

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
      final existing = await _client
          .from('platform_settings')
          .select('id')
          .eq('setting_key', settingKey)
          .maybeSingle();

      if (existing != null) {
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
      } else {
        final response = await _client
            .from('platform_settings')
            .insert({
              'setting_key': settingKey,
              'setting_value': value,
              'description': 'Configured dynamically via PetConnect AI Admin Portal',
            })
            .select()
            .single();
        return PlatformSettingModel.fromJson(response);
      }
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update setting by key: $e');
    }
  }

  @override
  Future<List<AdminUserEntryModel>> getAdminUserDirectory() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, role, is_active, created_at, updated_at')
          .order('created_at', ascending: false)
          .limit(200);

      return (response as List)
          .map((json) => AdminUserEntryModel.fromJson(json as Map<String, dynamic>))
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
  Future<AdminUserEntryModel> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _client
          .from('profiles')
          .update({'role': newRole, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId)
          .select('id, full_name, role, is_active, created_at, updated_at')
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
      await _client
          .from('profiles')
          .update({
            'is_active': !isSuspended,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update user suspension status: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to delete user: $e');
    }
  }

  @override
  Future<void> resetUserPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to send password reset: $e');
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
        data: {'full_name': fullName, 'role': role},
      );
      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
          'role': role,
          'is_active': true,
        });
      }
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create user account: $e');
    }
  }

  // Staff Management
  @override
  Future<List<StaffMemberModel>> getStaffMembers() async {
    try {
      final response = await _client
          .from('staff_members')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StaffMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback query to veterinarian profiles if staff_members table is fresh
      try {
        final profilesRes = await _client
            .from('profiles')
            .select()
            .inFilter('role', ['veterinarian', 'administrator'])
            .limit(50);
        return (profilesRes as List)
            .map((json) => StaffMemberModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
  }

  @override
  Future<StaffMemberModel> saveStaffMember(StaffMemberModel member) async {
    try {
      final json = member.toJson();
      final response = await _client
          .from('staff_members')
          .upsert(json)
          .select()
          .single();
      return StaffMemberModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to save staff member: $e');
    }
  }

  @override
  Future<void> deleteStaffMember(String id) async {
    try {
      await _client.from('staff_members').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete staff member: $e');
    }
  }

  // Content Management System (CMS)
  @override
  Future<List<AdminArticleModel>> getArticles({String? status}) async {
    try {
      var query = _client.from('educational_articles').select();
      if (status != null && status != 'All') {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false).limit(100);
      return (response as List)
          .map((json) => AdminArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final query = _client.from('community_posts').select();
        final response = await query.order('created_at', ascending: false).limit(50);
        return (response as List)
            .map((json) => AdminArticleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
  }

  @override
  Future<AdminArticleModel> saveArticle(AdminArticleModel article) async {
    try {
      final json = article.toJson();
      final response = await _client
          .from('educational_articles')
          .upsert(json)
          .select()
          .single();
      return AdminArticleModel.fromJson(response);
    } catch (_) {
      // If table differs, upsert to community_posts
      final response = await _client
          .from('community_posts')
          .upsert({
            if (article.id.isNotEmpty) 'id': article.id,
            'caption': '${article.title}: ${article.summary}',
            'category': article.category,
            'created_at': article.createdAt.toIso8601String(),
          })
          .select()
          .single();
      return AdminArticleModel.fromJson(response);
    }
  }

  @override
  Future<void> deleteArticle(String id) async {
    try {
      await _client.from('educational_articles').delete().eq('id', id);
    } catch (_) {
      await _client.from('community_posts').delete().eq('id', id);
    }
  }

  // Live Database Table Assessment
  @override
  Future<Map<String, int>> getDatabaseTableCounts() async {
    final tables = [
      'profiles',
      'pets',
      'appointments',
      'consultations',
      'rescue_missions',
      'lost_pet_alerts',
      'rescue_shelters',
      'audit_logs',
    ];

    final counts = <String, int>{};

    for (final tbl in tables) {
      try {
        final res = await _client
            .from(tbl)
            .select('id')
            .count(CountOption.exact);
        counts[tbl] = res.count;
      } catch (_) {
        counts[tbl] = 0;
      }
    }

    return counts;
  }

  // Moderation
  @override
  Future<List<Map<String, dynamic>>> getFlaggedContent() async {
    try {
      final response = await _client
          .from('community_posts')
          .select()
          .eq('is_flagged', true)
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch moderation queue: $e');
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
