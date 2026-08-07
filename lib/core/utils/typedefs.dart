import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Common functional typedefs used across layers.
///
/// Repositories return these so the domain/presentation layers handle success
/// and failure explicitly via `dartz`'s [Either] (`Left` = failure,
/// `Right` = value).

/// An async result that may fail with a [Failure] or succeed with [T].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// A synchronous result that may fail with a [Failure] or succeed with [T].
typedef Result<T> = Either<Failure, T>;

/// An async result with no meaningful success value (side-effect only).
typedef ResultVoid = Future<Either<Failure, void>>;

/// A JSON map.
typedef Json = Map<String, dynamic>;

/// A list of JSON maps.
typedef JsonList = List<Map<String, dynamic>>;

/// A parameterless async action returning a result.
typedef AsyncAction<T> = Future<T> Function();
