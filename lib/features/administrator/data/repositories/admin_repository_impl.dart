import 'package:dartz/dartz.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/administrator/data/datasources/admin_remote_datasource.dart';
import 'package:petconnect_ai/features/administrator/data/models/audit_log_model.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  ResultFuture<List<AuditLogEntry>> getAuditLogs() async {
    try {
      final list = await _remote.getAuditLogs();
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<AuditLogEntry> createAuditLog(AuditLogEntry entry) async {
    try {
      final model = AuditLogModel(
        id: entry.id,
        actorId: entry.actorId,
        action: entry.action,
        resourceType: entry.resourceType,
        resourceId: entry.resourceId,
        severity: entry.severity,
        metadata: entry.metadata,
        createdAt: entry.createdAt,
      );
      final created = await _remote.createAuditLog(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PlatformSetting>> getPlatformSettings() async {
    try {
      final list = await _remote.getPlatformSettings();
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<PlatformSetting> updatePlatformSetting(
    String settingId,
    Map<String, dynamic> value,
  ) async {
    try {
      final updated = await _remote.updatePlatformSetting(settingId, value);
      return Right(updated);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<AdminUserEntry>> getAdminUserDirectory() async {
    try {
      final list = await _remote.getAdminUserDirectory();
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
