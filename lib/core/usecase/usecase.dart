import 'package:equatable/equatable.dart';

import 'package:petconnect_ai/core/utils/typedefs.dart';

/// Base contract for a single application use case (interactor).
///
/// A use case encapsulates one unit of business logic and is the only thing
/// the presentation layer calls into the domain with. It returns a
/// [ResultFuture] so success/failure is explicit.
///
/// ```dart
/// class GetPet implements UseCase<Pet, String> {
///   const GetPet(this._repo);
///   final PetRepository _repo;
///   @override
///   ResultFuture<Pet> call(String petId) => _repo.getPet(petId);
/// }
/// ```
abstract interface class UseCase<Type, Params> {
  ResultFuture<Type> call(Params params);
}

/// Synchronous variant for logic that doesn't touch async boundaries.
abstract interface class SyncUseCase<Type, Params> {
  Result<Type> call(Params params);
}

/// A streaming use case (e.g. realtime subscriptions).
abstract interface class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// Sentinel for use cases that take no parameters.
///
/// ```dart
/// class SignOut implements UseCase<void, NoParams> { ... }
/// await signOut(const NoParams());
/// ```
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => <Object?>[];
}

/// Common parameters for paginated queries.
class PaginationParams extends Equatable {
  const PaginationParams({this.page = 1, this.pageSize = 20, this.search});

  final int page;
  final int pageSize;
  final String? search;

  int get offset => (page - 1) * pageSize;

  PaginationParams copyWith({int? page, int? pageSize, String? search}) =>
      PaginationParams(
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => <Object?>[page, pageSize, search];
}
