import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/veterinarian/data/datasources/vet_remote_datasource.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/clinic_analytics_summary_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/repositories/vet_repository_impl.dart';

class MockVetRemoteDataSource extends Mock implements VetRemoteDataSource {}

void main() {
  late MockVetRemoteDataSource mockRemote;
  late VetRepositoryImpl repository;

  final tModel = ClinicAnalyticsSummaryModel(
    clinicId: 'clinic-1',
    clinicName: 'Paws & Care',
    reportMonth: DateTime(2026, 8, 1),
    totalAppointments: 42,
    completedAppointments: 36,
    cancelledAppointments: 4,
    avgDurationMinutes: 22.5,
    totalConsultations: 30,
    totalPrescriptions: 18,
    totalVaccinations: 12,
    uniquePatients: 25,
    refreshedAt: DateTime(2026, 8, 14),
  );

  setUp(() {
    mockRemote = MockVetRemoteDataSource();
    repository = VetRepositoryImpl(mockRemote);
  });

  group('VetRepository getClinicAnalytics (Phase 11)', () {
    test(
      'returns Right(List<ClinicAnalyticsSummary>) on datasource success',
      () async {
        when(
          () => mockRemote.getClinicAnalytics('clinic-1'),
        ).thenAnswer((_) async => [tModel]);

        final result = await repository.getClinicAnalytics('clinic-1');
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right'),
          (rows) {
            expect(rows.length, 1);
            expect(rows.first.clinicId, 'clinic-1');
            expect(rows.first.totalAppointments, 42);
          },
        );
        verify(() => mockRemote.getClinicAnalytics('clinic-1')).called(1);
      },
    );

    test(
      'returns Left(ServerFailure) when datasource throws ServerException',
      () async {
        when(
          () => mockRemote.getClinicAnalytics('clinic-1'),
        ).thenThrow(const ServerException('DB connection failed'));

        final result = await repository.getClinicAnalytics('clinic-1');
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
          () => mockRemote.getClinicAnalytics('clinic-1'),
        ).thenThrow(Exception('Unexpected'));

        final result = await repository.getClinicAnalytics('clinic-1');
        expect(result.isLeft(), isTrue);
      },
    );

    test('returns Right([]) when datasource returns empty list', () async {
      when(
        () => mockRemote.getClinicAnalytics('clinic-99'),
      ).thenAnswer((_) async => []);

      final result = await repository.getClinicAnalytics('clinic-99');
      expect(result.isRight(), isTrue);
      result.fold(
        (f) => fail('Expected Right'),
        (rows) => expect(rows, isEmpty),
      );
    });
  });
}
