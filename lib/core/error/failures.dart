import 'package:equatable/equatable.dart';

/// Domain-layer failures.
///
/// Repositories return `Either<Failure, T>` (via `dartz`). Failures are the
/// only error type the domain and presentation layers ever see — data-layer
/// [AppException]s are mapped to these at the repository boundary.
///
/// Presentation code should `switch` over the sealed subtypes to render the
/// right message / retry affordance.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[message, statusCode];
}

/// Backend / server error.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// Local cache / storage error.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// No / lost connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Authentication / session failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

/// Authorization failure — not permitted (RLS / role).
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.statusCode});
}

/// Input validation failure, optionally per-field.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => <Object?>[message, statusCode, fieldErrors];
}

/// Resource not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Operation timed out.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

/// Uncategorized failure.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
