import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/domain/repositories/admin_repository.dart';

class GetAuditLogs {
  const GetAuditLogs(this._repository);
  final AdminRepository _repository;
  ResultFuture<List<AuditLogEntry>> call() => _repository.getAuditLogs();
}

class CreateAuditLog {
  const CreateAuditLog(this._repository);
  final AdminRepository _repository;
  ResultFuture<AuditLogEntry> call(AuditLogEntry entry) =>
      _repository.createAuditLog(entry);
}

class GetPlatformSettings {
  const GetPlatformSettings(this._repository);
  final AdminRepository _repository;
  ResultFuture<List<PlatformSetting>> call() =>
      _repository.getPlatformSettings();
}

class UpdatePlatformSetting {
  const UpdatePlatformSetting(this._repository);
  final AdminRepository _repository;
  ResultFuture<PlatformSetting> call(
    String settingId,
    Map<String, dynamic> value,
  ) => _repository.updatePlatformSetting(settingId, value);
}

class GetAdminUserDirectory {
  const GetAdminUserDirectory(this._repository);
  final AdminRepository _repository;
  ResultFuture<List<AdminUserEntry>> call() =>
      _repository.getAdminUserDirectory();
}
