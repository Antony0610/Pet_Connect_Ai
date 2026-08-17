import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/administrator/data/datasources/admin_remote_datasource.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_report_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/repositories/admin_repository_impl.dart';

class MockAdminRemoteDataSource extends Mock
    implements AdminRemoteDataSource {}

void main() {
  late MockAdminRemoteDataSource mockRemote;
  late AdminRepositoryImpl repository;

  final tModel = PlatformReportSummaryModel(
    reportMonth: DateTime(2026, 8, 1),
    totalUsers: 500,
    totalPetOwners: 380,
    totalVeterinarians: 75,
    totalRescuers: 40,
    totalAdministrators: 5,
    totalAppointments: 890,
    completedAppointments: 820,
    totalAiConversations: 1200,
    totalAiScans: 450,
    totalRescueMissions: 30,
    totalLostPetAlerts: 15,
    refreshedAt: DateTime(2026, 8, 14, 12),
  );

  setUp(() {
    mockRemote = MockAdminRemoteDataSource();
    repository = AdminRepositoryImpl(mockRemote);
  });

  group('AdminRepository getPlatformReports (Phase 11)', () {
    test(
      'returns Right(PlatformReportSummary) on datasource success',
      () async {
        when(
          () => mockRemote.getPlatformReports(),
        ).thenAnswer((_) async => tModel);

        final result = await repository.getPlatformReports();
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right'),
          (summary) {
            expect(summary, isNotNull);
            expect(summary!.totalUsers, 500);
            expect(summary.totalAiScans, 450);
          },
        );
        verify(() => mockRemote.getPlatformReports()).called(1);
      },
    );

    test(
      'returns Right(null) when datasource returns null (no data yet)',
      () async {
        when(
          () => mockRemote.getPlatformReports(),
        ).thenAnswer((_) async => null);

        final result = await repository.getPlatformReports();
        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right'),
          (summary) => expect(summary, isNull),
        );
      },
    );

    test(
      'returns Left(ServerFailure) when datasource throws ServerException',
      () async {
        when(
          () => mockRemote.getPlatformReports(),
        ).thenThrow(const ServerException('Permission denied'));

        final result = await repository.getPlatformReports();
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns Left(ServerFailure) when datasource throws generic exception',
      () async {
        when(
          () => mockRemote.getPlatformReports(),
        ).thenThrow(Exception('Network timeout'));

        final result = await repository.getPlatformReports();
        expect(result.isLeft(), isTrue);
      },
    );
  });
}
