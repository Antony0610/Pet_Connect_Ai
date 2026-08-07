# Architecture

PetConnect AI is a production-grade, AI-powered pet care platform built on
Flutter and Supabase. It serves four interconnected portals — **Pet Owner**
(primary), **Veterinarian**, **Volunteer & Rescue**, and **Administrator** —
plus a shared **Community** area. This document describes the architectural
foundation that keeps a system of this size coherent, testable, and safe to
evolve.

---

## 1. Guiding Principles

The codebase follows **Clean Architecture** organized **feature-first**. Two
ideas do the heavy lifting:

1. **Separation of concerns by layer.** Each feature is split into three
   layers — `presentation`, `domain`, and `data` — each with a single,
   well-defined responsibility.
2. **The Dependency Rule.** Source-code dependencies point *inward*, toward the
   domain. Nothing in an inner layer knows anything about an outer layer.

```
presentation  ──►  domain  ◄──  data
                   (depends on nothing)
```

The `domain` layer is the stable center of the application. It has no import of
Flutter, Supabase, Dio, or any other framework. `presentation` and `data` both
depend on `domain`; they never depend on each other.

### Why Clean Architecture for a four-portal, multi-role app

- **Independent portals, shared core.** Pet Owner, Veterinarian, Volunteer &
  Rescue, and Administrator are effectively four apps that share entities,
  infrastructure, and design tokens. Feature-first slicing lets each portal evolve on
  its own cadence without cross-contamination, while `core/`, `router/`, and
  `shared/` provide the common ground.
- **Role-specific business rules.** Access, permissions, and workflows differ
  per role. Encoding those rules as framework-free use cases in `domain` keeps
  them explicit, unit-testable, and impossible to accidentally bypass from a
  widget.
- **Backend independence.** Supabase is an implementation detail hidden behind
  repository interfaces. If a datasource changes (a table becomes an Edge
  Function, a query moves to pgvector), the change is contained to the `data`
  layer.
- **Longevity.** A production app lives for years. The Dependency Rule protects
  business logic from churn in UI frameworks and SDKs.

---

## 2. The Layers

### 2.1 Presentation

Everything the user sees and touches: screens, widgets, and controllers.

- **Screens** (`presentation/screens`) compose widgets into routes.
- **Widgets** (`presentation/widgets`) are feature-local, reusable UI pieces.
- **Controllers** (`presentation/controllers`) hold screen state and orchestrate
  use cases. They are Riverpod `AsyncNotifier`/`Notifier` classes — see
  `STATE_MANAGEMENT.md`.

The presentation layer depends on `domain` only. It calls use cases, receives
entities or `Failure`s, and maps them to view state. **No business logic and no
data access live here.**

```dart
// presentation/controllers/pet_list_controller.dart
@riverpod
class PetListController extends _$PetListController {
  @override
  Future<List<Pet>> build() async {
    final getPets = ref.watch(getPetsProvider);
    final result = await getPets(NoParams());
    return result.fold(
      (failure) => throw failure,      // surfaced as AsyncError to the UI
      (pets) => pets,
    );
  }
}
```

### 2.2 Domain

The framework-free heart of the application.

- **Entities** (`domain/entities`) are immutable business objects (built with
  freezed). They contain no serialization concerns.
- **Repositories** (`domain/repositories`) are *abstract* interfaces describing
  what the app can do, expressed in domain terms.
- **Use cases** (`domain/usecases`) are single-responsibility application
  actions (e.g. `GetPets`, `BookAppointment`, `EnableLostMode`). Each returns
  `Either<Failure, T>`.

The domain layer imports nothing outside itself except `dartz` (for `Either`)
and shared domain types. This is what makes it trivially unit-testable.

```dart
// domain/usecases/get_pets.dart
class GetPets implements UseCase<List<Pet>, NoParams> {
  const GetPets(this._repository);
  final PetRepository _repository;         // abstract interface

  @override
  Future<Either<Failure, List<Pet>>> call(NoParams params) {
    return _repository.getPets();
  }
}
```

### 2.3 Data

The layer that talks to the outside world.

- **Datasources** (`data/datasources`) perform raw I/O against Supabase
  (Postgres, Storage, Realtime, Edge Functions) or, for non-Supabase HTTP, Dio.
  They throw **typed Exceptions** on failure.
- **Models** (`data/models`) extend or map to entities and add
  serialization (`fromJson`/`toJson` via freezed + json_serializable).
- **Repository implementations** (`data/repositories`) implement the abstract
  interfaces from `domain`. They call datasources, catch typed Exceptions, and
  translate them into `Failure`s wrapped in `Either`.

```dart
// data/repositories/pet_repository_impl.dart
class PetRepositoryImpl implements PetRepository {
  const PetRepositoryImpl(this._remote);
  final PetRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Pet>>> getPets() async {
    try {
      final models = await _remote.fetchPets();
      return Right(models);                        // PetModel is a Pet
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(const NetworkFailure());
    }
  }
}
```

---

## 3. Cross-Cutting Structure

Three top-level directories sit alongside `features/` and are shared across all
portals.

### `core/`
Framework wiring and app-wide primitives that are not feature-specific:
`config`, `constants`, `error`, `network`, `providers` (Riverpod DI — the
app-wide Supabase client, Dio client, connectivity, and logger are exposed
here), `router`, `theme` (`tokens`, `component_tokens`), `utils` (with
`extensions`), and `usecase` (the base `UseCase` contract and `NoParams`).

External-system wrappers do **not** get a top-level `services/` layer. Instead:
app-wide clients (Supabase, Dio) are provided through `core/providers`;
cross-cutting infrastructure wrappers (notifications, location, storage), when
built, live under `core/` and are injected via Riverpod; and feature-owned
integrations (the AI assistant, the smart collar) live inside their own feature
module's `data/datasources`. This keeps SDK details in one place per concern and
fully mockable, without pre-scaffolding empty folders.

### `shared/`
Reusable UI and cross-feature domain/data: `shared/widgets`
(buttons, cards, inputs, chips, loading, states, layout, avatar),
plus `shared/domain/entities` and `shared/data/models` for types used by more
than one feature.

See `FOLDER_STRUCTURE.md` for the complete tree.

---

## 4. Data Flow

A single user action travels inward and back out along a fixed path:

```
UI (screen/widget)
   │  user intent
   ▼
Controller (Riverpod AsyncNotifier)   ── presentation
   │  calls
   ▼
UseCase                               ── domain
   │  calls (abstract)
   ▼
Repository (interface → impl)         ── domain / data
   │  calls
   ▼
DataSource                            ── data
   │  I/O
   ▼
Supabase (Auth · Postgres · Storage · Realtime · Edge Functions · RLS)
```

The response returns along the reverse path, transforming as it goes:

```
Supabase rows/JSON
   → Model (deserialize)
   → Entity (as domain type)
   → Either<Failure, Entity>   (repository)
   → Either passed through      (use case)
   → AsyncValue<State>          (controller folds Either)
   → rebuilt UI
```

Realtime is a variation on the same theme: a datasource exposes a Supabase
`Stream`, the repository maps rows to entities, and a `StreamProvider` (or an
`AsyncNotifier` listening to the stream) feeds the UI.

---

## 5. Error Handling: `Either<Failure, T>`

Errors are values, not surprises. The flow is uniform across every feature:

1. **Datasources throw typed Exceptions** (`ServerException`,
   `NetworkException`, `CacheException`, `AuthException`, etc.).
2. **Repositories catch** those Exceptions and return the corresponding
   **sealed `Failure`** from `core/error/failures.dart`, wrapped as
   `Left(failure)`. Success is `Right(value)`.
3. **Use cases** propagate the `Either` untouched (or combine several).
4. **Controllers `fold`** the `Either`: `Left` becomes an `AsyncError` /
   user-facing message; `Right` becomes state.

```dart
// core/error/failures.dart (sketch)
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ServerFailure   extends Failure { const ServerFailure([super.m = 'Server error']); }
class NetworkFailure  extends Failure { const NetworkFailure([super.m = 'No connection']); }
class AuthFailure     extends Failure { const AuthFailure([super.m = 'Auth error']); }
class ValidationFailure extends Failure { const ValidationFailure(super.m); }
```

**Rationale.** Modeling failure as data means the type system forces every
caller to handle both branches. There are no silent `null`s and no unhandled
exceptions bubbling into the UI. Because `Failure`s are sealed, exhaustive
`switch` handling is checked by the compiler as the taxonomy grows.

---

## 6. Dependency Injection with Riverpod

PetConnect AI uses **Riverpod providers as its DI mechanism** — there is no
`get_it` service locator. Dependencies are declared as providers and resolved
through `ref`.

- **Root/shared providers** live in `core/providers/core_providers.dart` (e.g. the Supabase
  client, Dio client, connectivity, logger) and `core/providers/theme_providers.dart`.
- **Presentation controllers** live in each feature's
  `presentation/controllers` and `watch`/`read` the providers they need.

```dart
// core/providers/core_providers.dart (or a feature-scoped provider file)
@riverpod
PetRemoteDataSource petRemoteDataSource(Ref ref) =>
    PetRemoteDataSourceImpl(ref.watch(supabaseClientProvider));

@riverpod
PetRepository petRepository(Ref ref) =>
    PetRepositoryImpl(ref.watch(petRemoteDataSourceProvider));

@riverpod
GetPets getPets(Ref ref) => GetPets(ref.watch(petRepositoryProvider));
```

**Rationale.** Providers give compile-time-safe, lazily-instantiated, and
easily-overridable dependencies. The same override mechanism used in production
is used in tests (`ProviderContainer` / `ProviderScope` overrides), so wiring is
never duplicated. See `STATE_MANAGEMENT.md` for provider selection and lifecycle
guidance.

---

## 7. Testability

The architecture is designed so that each layer can be verified in isolation.

- **Domain (use cases)** — pure Dart, no Flutter. Mock the abstract repository,
  assert on the returned `Either`. Fast and deterministic.
- **Data (repositories)** — mock datasources; assert that thrown Exceptions map
  to the correct `Failure`, and that success maps to entities.
- **Data (datasources)** — mock the service/SDK client; assert query shape and
  deserialization.
- **Presentation (controllers)** — override use-case providers with fakes via
  `ProviderContainer`; drive the controller and assert on emitted
  `AsyncValue` states.
- **Presentation (widgets)** — widget tests with overridden controllers to
  render loading/error/data states from `shared/` and feature widgets.

Test folders mirror this split: `test/unit`, `test/widget`, `test/integration`.
Because the Dependency Rule keeps `domain` free of frameworks and DI is override-
based, the vast majority of business logic is covered by fast unit tests with no
device or network required.

---

## 8. Summary

- Feature-first slicing keeps four portals independent while sharing `core/`,
  `router/`, and `shared/`.
- The Dependency Rule points everything inward at a framework-free `domain`.
- Data flows UI → controller → use case → repository → datasource → Supabase and
  back, transforming model → entity → `Either` → `AsyncValue`.
- Errors are values (`Either<Failure, T>`), sealed and exhaustively handled.
- Riverpod is both the state and the DI mechanism, making the whole system
  override-friendly and testable.
