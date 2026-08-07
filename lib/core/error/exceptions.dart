/// Data-layer exceptions.
///
/// Thrown by data sources / services when an operation fails. They are caught
/// at the repository boundary and mapped to domain [Failure]s via
/// `FailureMapper`. Never let raw exceptions escape into the presentation
/// layer.
library;

/// Base class for all app exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType($message${statusCode != null ? ', '
                'status: $statusCode' : ''})';
}

/// A server / backend error (HTTP or Supabase RPC returned an error).
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.cause});
}

/// A local cache / storage error.
class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// No / lost network connectivity.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Authentication / session error (invalid credentials, expired session).
class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode, super.cause});
}

/// Authorization error — authenticated but not permitted (RLS / role).
class PermissionException extends AppException {
  const PermissionException(super.message, {super.statusCode, super.cause});
}

/// Input / payload validation error.
class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;
}

/// Requested resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}

/// Operation exceeded its time budget.
///
/// Named `RequestTimeoutException` (not `TimeoutException`) so it never shadows
/// `dart:async.TimeoutException` in files that import both.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'Request timed out']);
}

/// Fallback for anything not otherwise categorized.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred',
    // ignore: unused_element_parameter
    Object? cause,
  ]) : super(cause: cause);
}
