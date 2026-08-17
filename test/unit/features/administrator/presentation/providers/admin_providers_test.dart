import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_report_summary.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/security_posture_summary.dart';
import 'package:petconnect_ai/features/administrator/domain/repositories/admin_repository.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepo;

  final now = DateTime(2026, 8, 12);

  final tAuditLog = AuditLogEntry(
    id: 'log-1',
    actorId: 'admin-1',
    action: 'USER_ROLE_UPDATED',
    resourceType: 'profiles',
    resourceId: 'user-42',
    severity: 'INFO',
    createdAt: now,
  );

  final tSetting = PlatformSetting(
    id: 'setting-1',
    settingKey: 'maintenance_mode',
    settingValue: const {'enabled': false},
    description: 'Maintenance mode toggle',
    createdAt: now,
    updatedAt: now,
  );

  final tUser = AdminUserEntry(
    id: 'user-1',
    fullName: 'Sarah Connor',
    email: 'sarah@example.com',
    role: 'administrator',
    createdAt: now,
    updatedAt: now,
  );

  final tPosture = SecurityPostureSummary(
    postureRating: 'OPTIMAL',
    totalAuditEvents24h: 15,
    criticalEvents24h: 0,
    warningEvents24h: 2,
    infoEvents24h: 13,
    totalAuditEventsAllTime: 150,
    activeAdministrators: 3,
    totalSystemUsers: 50,
    rlsTablesProtected: 31,
    totalPublicTables: 31,
    auditLogImmutability: 'ENFORCED',
    roleEscalationGuard: 'ENFORCED',
    petOwnerSpoofingGuard: 'ENFORCED',
    refreshedAt: now,
  );

  setUp(() {
    mockRepo = MockAdminRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Admin Providers Unit Tests', () {
    test('adminAuditLogsProvider loads audit logs', () async {
      when(
        () => mockRepo.getAuditLogs(),
      ).thenAnswer((_) async => Right([tAuditLog]));

      final container = makeContainer();
      final logs = await container.read(adminAuditLogsProvider.future);

      expect(logs, [tAuditLog]);
      verify(() => mockRepo.getAuditLogs()).called(1);
    });

    test('adminPlatformSettingsProvider loads settings', () async {
      when(
        () => mockRepo.getPlatformSettings(),
      ).thenAnswer((_) async => Right([tSetting]));

      final container = makeContainer();
      final settings = await container.read(
        adminPlatformSettingsProvider.future,
      );

      expect(settings, [tSetting]);
      verify(() => mockRepo.getPlatformSettings()).called(1);
    });

    test('adminUserDirectoryProvider loads user directory', () async {
      when(
        () => mockRepo.getAdminUserDirectory(),
      ).thenAnswer((_) async => Right([tUser]));

      final container = makeContainer();
      final users = await container.read(adminUserDirectoryProvider.future);

      expect(users, [tUser]);
      expect(users.first.fullName, 'Sarah Connor');
      expect(users.first.role, 'administrator');
      verify(() => mockRepo.getAdminUserDirectory()).called(1);
    });

    test('adminPlatformReportsProvider loads platform reports', () async {
      final tReports = PlatformReportSummary(
        reportMonth: now,
        totalUsers: 100,
        totalPetOwners: 80,
        totalVeterinarians: 15,
        totalRescuers: 4,
        totalAdministrators: 1,
        totalAppointments: 200,
        completedAppointments: 180,
        totalAiConversations: 50,
        totalAiScans: 20,
        totalRescueMissions: 5,
        totalLostPetAlerts: 2,
        refreshedAt: now,
      );

      when(
        () => mockRepo.getPlatformReports(),
      ).thenAnswer((_) async => Right(tReports));

      final container = makeContainer();
      final report = await container.read(adminPlatformReportsProvider.future);

      expect(report, tReports);
      expect(report?.totalUsers, 100);
      verify(() => mockRepo.getPlatformReports()).called(1);
    });

    test('adminSecurityPostureProvider loads security posture summary (Phase 12)', () async {
      when(
        () => mockRepo.getSecurityPosture(),
      ).thenAnswer((_) async => Right(tPosture));

      final container = makeContainer();
      final posture = await container.read(adminSecurityPostureProvider.future);

      expect(posture, tPosture);
      expect(posture.postureRating, 'OPTIMAL');
      expect(posture.rlsTablesProtected, 31);
      verify(() => mockRepo.getSecurityPosture()).called(1);
    });
  });
}
