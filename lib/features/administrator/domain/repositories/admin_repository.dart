import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';

/// Repository interface for Administrator operations.
abstract class AdminRepository {
  ResultFuture<List<AuditLogEntry>> getAuditLogs();
  ResultFuture<AuditLogEntry> createAuditLog(AuditLogEntry entry);

  ResultFuture<List<PlatformSetting>> getPlatformSettings();
  ResultFuture<PlatformSetting> updatePlatformSetting(
    String settingId,
    Map<String, dynamic> value,
  );

  ResultFuture<List<AdminUserEntry>> getAdminUserDirectory();
}
