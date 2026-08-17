import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/realtime/data/datasources/realtime_remote_datasource.dart';
import 'package:petconnect_ai/features/realtime/data/repositories/realtime_repository_impl.dart';
import 'package:petconnect_ai/features/realtime/domain/usecases/realtime_usecases.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockRealtimeRemoteDataSource extends Mock
    implements RealtimeRemoteDataSource {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockRealtimeRemoteDataSource mockRemote;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late RealtimeRepositoryImpl repository;

  setUp(() {
    mockRemote = MockRealtimeRemoteDataSource();
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    repository = RealtimeRepositoryImpl(mockRemote, mockClient);
  });

  group('Phase 13 Realtime Repository & UseCases Tests', () {
    test('markAllNotificationsRead returns count on success', () async {
      when(() => mockRemote.markAllNotificationsRead()).thenAnswer((_) async => 4);

      final result = await repository.markAllNotificationsRead();

      expect(result, const Right(4));
      verify(() => mockRemote.markAllNotificationsRead()).called(1);
    });

    test('markAllNotificationsRead returns ServerFailure on ServerException', () async {
      when(
        () => mockRemote.markAllNotificationsRead(),
      ).thenThrow(const ServerException('Unauthorized', statusCode: 403));

      final result = await repository.markAllNotificationsRead();

      expect(result, isA<Left<Failure, int>>());
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
      verify(() => mockRemote.markAllNotificationsRead()).called(1);
    });

    test('MarkAllNotificationsRead usecase executes repository call', () async {
      when(() => mockRemote.markAllNotificationsRead()).thenAnswer((_) async => 2);

      final usecase = MarkAllNotificationsRead(repository);
      final result = await usecase();

      expect(result, const Right(2));
    });

    test('MarkNotificationRead usecase executes repository call', () async {
      when(() => mockRemote.markNotificationRead('notif-99')).thenAnswer((_) async {});

      final usecase = MarkNotificationRead(repository);
      final result = await usecase('notif-99');

      expect(result, const Right(null));
      verify(() => mockRemote.markNotificationRead('notif-99')).called(1);
    });
  });
}
