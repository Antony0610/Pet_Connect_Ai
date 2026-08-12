import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/domain/entities/auth_session.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/create_account.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/get_current_session.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/get_user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/resend_email_otp.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/reset_password_for_email.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_out.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/upsert_user_profile.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/verify_email_otp.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  const tSession = AuthSession(userId: 'u123', email: 'test@example.com');
  const tProfile = UserProfile(
    id: 'u123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: AppPortal.petOwner,
  );

  group('Auth UseCases Unit Tests', () {
    test('GetCurrentSession calls repository.currentSession', () async {
      when(
        () => mockRepository.currentSession(),
      ).thenAnswer((_) async => const Right<Failure, AuthSession?>(tSession));

      final useCase = GetCurrentSession(mockRepository);
      final result = await useCase(const NoParams());

      expect(result, const Right<Failure, AuthSession?>(tSession));
      verify(() => mockRepository.currentSession()).called(1);
    });

    test('SignInWithPassword calls repository.signInWithPassword', () async {
      when(
        () => mockRepository.signInWithPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => const Right<Failure, AuthSession>(tSession));

      final useCase = SignInWithPassword(mockRepository);
      final result = await useCase(
        const SignInParams(email: 'test@example.com', password: 'Password123'),
      );

      expect(result, const Right<Failure, AuthSession>(tSession));
      verify(
        () => mockRepository.signInWithPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).called(1);
    });

    test('CreateAccount calls repository.signUp', () async {
      when(
        () => mockRepository.signUp(
          email: 'test@example.com',
          password: 'Password123',
          fullName: 'Test User',
          role: AppPortal.petOwner,
          phone: null,
        ),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final useCase = CreateAccount(mockRepository);
      final result = await useCase(
        const CreateAccountParams(
          email: 'test@example.com',
          password: 'Password123',
          fullName: 'Test User',
          role: AppPortal.petOwner,
        ),
      );

      expect(result, const Right<Failure, void>(null));
      verify(
        () => mockRepository.signUp(
          email: 'test@example.com',
          password: 'Password123',
          fullName: 'Test User',
          role: AppPortal.petOwner,
          phone: null,
        ),
      ).called(1);
    });

    test('VerifyEmailOtp calls repository.verifyEmailOtp', () async {
      when(
        () => mockRepository.verifyEmailOtp(
          email: 'test@example.com',
          token: '123456',
        ),
      ).thenAnswer((_) async => const Right<Failure, AuthSession>(tSession));

      final useCase = VerifyEmailOtp(mockRepository);
      final result = await useCase(
        const VerifyEmailOtpParams(email: 'test@example.com', token: '123456'),
      );

      expect(result, const Right<Failure, AuthSession>(tSession));
      verify(
        () => mockRepository.verifyEmailOtp(
          email: 'test@example.com',
          token: '123456',
        ),
      ).called(1);
    });

    test('ResendEmailOtp calls repository.resendEmailOtp', () async {
      when(
        () => mockRepository.resendEmailOtp(email: 'test@example.com'),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final useCase = ResendEmailOtp(mockRepository);
      final result = await useCase('test@example.com');

      expect(result, const Right<Failure, void>(null));
      verify(
        () => mockRepository.resendEmailOtp(email: 'test@example.com'),
      ).called(1);
    });

    test('SignOut calls repository.signOut', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final useCase = SignOut(mockRepository);
      final result = await useCase(const NoParams());

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepository.signOut()).called(1);
    });

    test(
      'ResetPasswordForEmail calls repository.resetPasswordForEmail',
      () async {
        when(
          () => mockRepository.resetPasswordForEmail(email: 'test@example.com'),
        ).thenAnswer((_) async => const Right<Failure, void>(null));

        final useCase = ResetPasswordForEmail(mockRepository);
        final result = await useCase('test@example.com');

        expect(result, const Right<Failure, void>(null));
        verify(
          () => mockRepository.resetPasswordForEmail(email: 'test@example.com'),
        ).called(1);
      },
    );

    test('GetUserProfile calls repository.getUserProfile', () async {
      when(
        () => mockRepository.getUserProfile(userId: 'u123'),
      ).thenAnswer((_) async => const Right<Failure, UserProfile?>(tProfile));

      final useCase = GetUserProfile(mockRepository);
      final result = await useCase('u123');

      expect(result, const Right<Failure, UserProfile?>(tProfile));
      verify(() => mockRepository.getUserProfile(userId: 'u123')).called(1);
    });

    test('UpsertUserProfile calls repository.upsertUserProfile', () async {
      when(
        () => mockRepository.upsertUserProfile(tProfile),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final useCase = UpsertUserProfile(mockRepository);
      final result = await useCase(tProfile);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepository.upsertUserProfile(tProfile)).called(1);
    });

    test('SignInWithPassword returns Left(Failure) on error', () async {
      const failure = AuthFailure('Invalid login credentials');
      when(
        () => mockRepository.signInWithPassword(
          email: 'test@example.com',
          password: 'WrongPassword',
        ),
      ).thenAnswer((_) async => const Left<Failure, AuthSession>(failure));

      final useCase = SignInWithPassword(mockRepository);
      final result = await useCase(
        const SignInParams(
          email: 'test@example.com',
          password: 'WrongPassword',
        ),
      );

      expect(result, const Left<Failure, AuthSession>(failure));
    });
  });
}
