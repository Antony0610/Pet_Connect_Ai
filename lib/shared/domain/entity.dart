import 'package:equatable/equatable.dart';

/// Base class for domain entities.
///
/// Entities are immutable, framework-free business objects that live in the
/// domain layer. They extend [Equatable] for value equality. Data-layer models
/// (DTOs) map *to* these; the domain and presentation layers only ever see
/// entities, never DTOs.
abstract class Entity extends Equatable {
  const Entity();

  @override
  bool? get stringify => true;
}

/// A paginated result wrapper returned by list use cases.
class Paginated<T> extends Equatable {
  const Paginated({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final int? total;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[items, page, hasMore, total];
}
