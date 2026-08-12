import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/administrator/data/datasources/admin_remote_datasource.dart';
import 'package:petconnect_ai/features/administrator/data/repositories/admin_repository_impl.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/domain/repositories/admin_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

final adminAuditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAuditLogs();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (logs) => logs,
  );
});

final adminPlatformSettingsProvider = FutureProvider<List<PlatformSetting>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getPlatformSettings();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});

final adminUserDirectoryProvider = FutureProvider<List<AdminUserEntry>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAdminUserDirectory();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (users) => users,
  );
});
