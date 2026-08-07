import 'exceptions.dart';
import 'failures.dart';

/// Maps data-layer [AppException]s to domain-layer [Failure]s.
///
/// Call this at the repository boundary inside a `try/catch`:
///
/// ```dart
/// try {
///   final dto = await remoteDataSource.fetch();
///   return Right(dto.toEntity());
/// } on AppException catch (e) {
///   return Left(FailureMapper.fromException(e));
/// } catch (e) {
///   return Left(FailureMapper.fromUnknown(e));
/// }
/// ```
abstract final class FailureMapper {
  const FailureMapper._();

  static Failure fromException(AppException e) => switch (e) {
        ServerException() => ServerFailure(e.message, statusCode: e.statusCode),
        CacheException() => CacheFailure(e.message),
        NetworkException() => NetworkFailure(e.message),
        AuthException() => AuthFailure(e.message, statusCode: e.statusCode),
        PermissionException() =>
          PermissionFailure(e.message, statusCode: e.statusCode),
        ValidationException() =>
          ValidationFailure(e.message, fieldErrors: e.fieldErrors),
        NotFoundException() => NotFoundFailure(e.message),
        RequestTimeoutException() => TimeoutFailure(e.message),
        UnknownException() => UnknownFailure(e.message),
      };

  /// Fallback for anything that isn't an [AppException].
  static Failure fromUnknown(Object error) =>
      UnknownFailure(error.toString());
}
