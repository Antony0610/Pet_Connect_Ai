import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petconnect_ai/features/auth/data/models/auth_session_model.dart';
import 'package:petconnect_ai/features/auth/data/models/user_profile_model.dart';
import 'package:petconnect_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const UserProfileModel(
        id: 'fallback',
        email: 'fallback@example.com',
        fullName: 'Fallback',
        role: AppPortal.petOwner,
      ),
    );
  });

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemote);
  });

  const tSessionModel = AuthSessionModel(
    userId: 'u123',
    email: 'test@example.com',
  );
  const tProfileModel = UserProfileModel(
    id: 'u123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: AppPortal.petOwner,
  );
  const tProfile = UserProfile(
    id: 'u123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: AppPortal.petOwner,
  );

  group('AuthRepositoryImpl Unit Tests', () {
    test('currentSession returns AuthSession on success', () async {
      when(() => mockRemote.getCurrentSession()).thenReturn(tSessionModel);

      final result = await repository.currentSession();

      expect(result.isRight(), true);
      result.fold(
        (Failure f) => fail('Should be Right'),
        (AuthSession? s) => expect(s?.userId, 'u123'),
      );
    });

    test('signInWithPassword returns AuthSession on success', () async {
      when(
        () => mockRemote.signInWithPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => tSessionModel);

      final result = await repository.signInWithPassword(
        email: 'test@example.com',
        password: 'Password123',
      );

      expect(result.isRight(), true);
      result.fold(
        (Failure f) => fail('Should be Right'),
        (AuthSession s) => expect(s.userId, 'u123'),
      );
    });

    test('signInWithPassword maps AuthException to Failure', () async {
      when(
        () => mockRemote.signInWithPassword(
          email: 'test@example.com',
          password: 'WrongPassword',
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final result = await repository.signInWithPassword(
        email: 'test@example.com',
        password: 'WrongPassword',
      );

      expect(result.isLeft(), true);
      result.fold(
        (Failure f) => expect(f.message, 'Invalid login credentials'),
        (AuthSession s) => fail('Should be Left'),
      );
    });

    test('signUp completes with Right(null) on success', () async {
      when(
        () => mockRemote.signUp(
          email: 'test@example.com',
          password: 'Password123',
          fullName: 'Test User',
          role: AppPortal.petOwner,
          phone: null,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.signUp(
        email: 'test@example.com',
        password: 'Password123',
        fullName: 'Test User',
        role: AppPortal.petOwner,
      );

      expect(result, const Right<Failure, void>(null));
    });

    test('signOut completes with Right(null) on success', () async {
      when(() => mockRemote.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRemote.signOut()).called(1);
    });

    test(
      'resetPasswordForEmail completes with Right(null) on success',
      () async {
        when(
          () => mockRemote.resetPasswordForEmail(email: 'test@example.com'),
        ).thenAnswer((_) async {});

        final result = await repository.resetPasswordForEmail(
          email: 'test@example.com',
        );

        expect(result, const Right<Failure, void>(null));
        verify(
          () => mockRemote.resetPasswordForEmail(email: 'test@example.com'),
        ).called(1);
      },
    );

    test('getUserProfile returns UserProfile on success', () async {
      when(
        () => mockRemote.getUserProfile(userId: 'u123'),
      ).thenAnswer((_) async => tProfileModel);

      final result = await repository.getUserProfile(userId: 'u123');

      expect(result.isRight(), true);
      result.fold(
        (Failure f) => fail('Should be Right'),
        (UserProfile? profile) => expect(profile?.id, 'u123'),
      );
    });

    test('upsertUserProfile completes with Right(null) on success', () async {
      when(() => mockRemote.upsertUserProfile(any())).thenAnswer((_) async {});

      final result = await repository.upsertUserProfile(tProfile);

      expect(result, const Right<Failure, void>(null));
    });
  });
}
