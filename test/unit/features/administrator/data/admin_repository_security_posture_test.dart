import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/administrator/data/datasources/admin_remote_datasource.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_setting_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/security_posture_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/repositories/admin_repository_impl.dart';

class MockAdminRemoteDataSource extends Mock
    implements AdminRemoteDataSource {}

void main() {
  late MockAdminRemoteDataSource mockRemote;
  late AdminRepositoryImpl repository;

  final tPostureModel = SecurityPostureSummaryModel(
    postureRating: 'OPTIMAL',
    totalAuditEvents24h: 18,
    criticalEvents24h: 0,
    warningEvents24h: 1,
    infoEvents24h: 17,
    totalAuditEventsAllTime: 230,
    activeAdministrators: 4,
    totalSystemUsers: 60,
    rlsTablesProtected: 31,
    totalPublicTables: 31,
    auditLogImmutability: 'ENFORCED',
    roleEscalationGuard: 'ENFORCED',
    petOwnerSpoofingGuard: 'ENFORCED',
    refreshedAt: DateTime.parse('2026-08-17T18:30:00.000Z'),
  );

  final tSettingModel = PlatformSettingModel(
    id: 'setting-1',
    settingKey: 'maintenance_mode',
    settingValue: const {'enabled': true},
    description: 'Maintenance switch',
    updatedBy: 'admin-1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRemote = MockAdminRemoteDataSource();
    repository = AdminRepositoryImpl(mockRemote);
  });

  group('AdminRepository getSecurityPosture (Phase 12)', () {
    test(
      'returns Right(SecurityPostureSummary) on datasource success',
      () async {
        when(
          () => mockRemote.getSecurityPosture(),
        ).thenAnswer((_) async => tPostureModel);

        final result = await repository.getSecurityPosture();
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right'),
          (summary) {
            expect(summary.postureRating, 'OPTIMAL');
            expect(summary.totalAuditEvents24h, 18);
            expect(summary.criticalEvents24h, 0);
            expect(summary.rlsTablesProtected, 31);
          },
        );
        verify(() => mockRemote.getSecurityPosture()).called(1);
      },
    );

    test(
      'returns Left(ServerFailure) when datasource throws ServerException',
      () async {
        when(
          () => mockRemote.getSecurityPosture(),
        ).thenThrow(const ServerException('Permission denied', statusCode: 403));

        final result = await repository.getSecurityPosture();
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns Left(ServerFailure) on generic exception',
      () async {
        when(
          () => mockRemote.getSecurityPosture(),
        ).thenThrow(Exception('RPC timeout'));

        final result = await repository.getSecurityPosture();
        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('AdminRepository updatePlatformSettingByKey (Phase 12)', () {
    test('returns Right(PlatformSetting) on successful update', () async {
      when(
        () => mockRemote.updatePlatformSettingByKey(
          'maintenance_mode',
          {'enabled': true},
        ),
      ).thenAnswer((_) async => tSettingModel);

      final result = await repository.updatePlatformSettingByKey(
        'maintenance_mode',
        {'enabled': true},
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right'),
        (setting) => expect(setting.settingKey, 'maintenance_mode'),
      );
    });

    test('returns Left(ServerFailure) when update fails', () async {
      when(
        () => mockRemote.updatePlatformSettingByKey(any(), any()),
      ).thenThrow(const ServerException('Update failed'));

      final result = await repository.updatePlatformSettingByKey(
        'maintenance_mode',
        {'enabled': true},
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
