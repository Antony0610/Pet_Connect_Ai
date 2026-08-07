# State Management

PetConnect AI uses **Riverpod** for both state management and dependency
injection. This document defines which provider type to reach for, the
controller pattern each feature screen follows, how providers are organized and
disposed, how they are tested, and how `flutter_hooks` fits in.

Stack: `flutter_riverpod`, `riverpod_annotation` + `riverpod_generator`
(codegen), `hooks_riverpod`, and `flutter_hooks`. Providers are written with the
`@riverpod` annotation and code generation; hand-written `StateNotifierProvider`
is not used in new code.

---

## 1. Why Riverpod

- **Compile-safe DI.** Providers are resolved through `ref` with no runtime
  service locator (see `ARCHITECTURE.md` §6). The same mechanism powers state
  and dependencies.
- **Override-based testing.** Any provider can be overridden in a
  `ProviderContainer`/`ProviderScope`, so tests reuse production wiring.
- **Fine-grained rebuilds.** `watch`/`select` rebuild only what changed.
- **First-class async.** `AsyncValue` models loading/data/error uniformly, which
  pairs cleanly with the `Either<Failure, T>` flow.

---

## 2. Provider Types — When to Use Which

| Provider | Use for | In PetConnect AI |
|----------|---------|------------------|
| `Provider` | Stateless dependencies / derived values | DI: services, repositories, use cases (in `core/providers`) |
| `NotifierProvider` (`@riverpod class`) | Mutable synchronous state | Simple UI/view state that isn't async |
| `AsyncNotifierProvider` (`@riverpod class`) | Async state with user actions | **Screen controllers** — the default for feature screens |
| `FutureProvider` (`@riverpod` fn) | One-shot async reads with no mutations | Fetch-and-display data (e.g. pet profile) |
| `StreamProvider` (`@riverpod` fn) | Continuous streams | **Supabase Realtime** subscriptions (chats, live telemetry) |

Guidance:

- Reach for an **`AsyncNotifier` controller** whenever a screen both *loads* data
  and *performs actions* on it.
- Use a plain **`FutureProvider`** for read-only data with no mutations.
- Use a **`StreamProvider`** to expose Supabase Realtime and collar telemetry
  streams to the UI.
- Use a plain **`Provider`** only for DI and pure derived values.

---

## 3. The Controller Pattern (AsyncNotifier per screen)

Each feature screen has an **`AsyncNotifier` controller** in the feature's
`presentation/controllers`. The controller:

1. Loads initial state in `build()`.
2. Exposes methods for user actions.
3. Calls **use cases**, folds the returned `Either<Failure, T>`, and updates
   `state` as an `AsyncValue`.

```dart
// features/pet_owner/presentation/controllers/pet_list_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pet_list_controller.g.dart';

@riverpod
class PetListController extends _$PetListController {
  @override
  Future<List<Pet>> build() async {
    return _load();
  }

  Future<List<Pet>> _load() async {
    final getPets = ref.watch(getPetsProvider);       // use case via DI
    final result = await getPets(const NoParams());
    return result.fold(
      (failure) => throw failure,   // becomes AsyncError for the UI
      (pets) => pets,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> addPet(AddPetParams params) async {
    final addPet = ref.read(addPetProvider);
    state = const AsyncLoading();
    final result = await addPet(params);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => state,               // then re-load, or optimistically update
    );
    await refresh();
  }
}
```

The screen consumes it and renders per `AsyncValue` branch:

```dart
class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petListControllerProvider);
    return pets.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(failure: e as Failure),
      data: (list) => PetList(pets: list),
    );
  }
}
```

**Rule:** controllers orchestrate; they hold no business rules (those are in use
cases) and perform no I/O directly (that is the data layer).

---

## 4. `ref` Usage

- **`ref.watch`** — reactive dependency; rebuilds/recomputes when the watched
  provider changes. Use in `build()` and controller `build()`.
- **`ref.read`** — one-off access inside action methods and callbacks (event
  handlers). Never `read` to derive state that should be reactive.
- **`ref.listen`** — side effects in response to change (navigation, snackbars).
- **`ref.select`** — subscribe to a slice of a value to minimize rebuilds.

```dart
// In a controller action: read (one-off), not watch
final bookAppointment = ref.read(bookAppointmentProvider);

// In build: watch (reactive)
final session = ref.watch(authSessionProvider);
```

---

## 5. Where Providers Live

- **DI providers** — services, repositories, and use cases — live in
  **`core/providers/core_providers.dart`** (and feature-local DI files where scoped to one
  feature). These are plain `@riverpod` functions returning a dependency.
- **State/controllers** — live in each feature's
  **`presentation/controllers`**.

This keeps the dependency graph in `core/providers` and screen state next to the
screens it serves.

```dart
// core/providers/core_providers.dart
@riverpod
GetPets getPets(Ref ref) => GetPets(ref.watch(petRepositoryProvider));

@riverpod
AddPet addPet(Ref ref) => AddPet(ref.watch(petRepositoryProvider));
```

---

## 6. Disposal and `autoDispose`

With codegen, `@riverpod` providers are **auto-disposed by default** — state is
released when no longer listened to. This is the right default for screen
controllers and screen-scoped reads.

- **Keep the default (auto-dispose)** for screen controllers, per-screen
  `Future`/`Stream` reads, and anything scoped to a route.
- **Keep alive** only long-lived, app-wide state (e.g. the auth session) using
  `ref.keepAlive()` or the `@Riverpod(keepAlive: true)` annotation.
- **Streams** (Supabase Realtime, collar telemetry) should auto-dispose so
  subscriptions close when the screen leaves the tree; use `ref.onDispose` for
  any manual cleanup.

```dart
@Riverpod(keepAlive: true)            // survives across screens
class AuthSessionController extends _$AuthSessionController { ... }

@riverpod                              // auto-disposed (default)
Stream<List<Message>> chatMessages(Ref ref, String threadId) {
  final ds = ref.watch(chatRemoteDataSourceProvider);
  ref.onDispose(() => /* close subscription if needed */ null);
  return ds.watchThread(threadId);     // Supabase Realtime stream
}
```

---

## 7. Supabase Realtime with StreamProvider

Realtime data (community chat, live collar location, appointment updates) is
exposed as a stream from a datasource, mapped to entities in the repository, and
surfaced via a `@riverpod` stream provider consumed with `AsyncValue`.

```dart
@riverpod
Stream<CollarTelemetry> collarTelemetry(Ref ref, String collarId) {
  final repo = ref.watch(smartCollarRepositoryProvider);
  return repo.watchTelemetry(collarId);   // entity stream, not raw rows
}

// UI
ref.watch(collarTelemetryProvider(collarId)).when(
  loading: () => const AppLoader(),
  error: (e, _) => AppErrorView(failure: e as Failure),
  data: (t) => BatteryGauge(level: t.batteryLevel),
);
```

---

## 8. Testing Providers with Overrides

Because DI is provider-based, tests override the providers they want to fake and
drive the controller through a `ProviderContainer`.

```dart
test('PetListController surfaces ServerFailure as AsyncError', () async {
  final container = ProviderContainer(
    overrides: [
      // Override the use case with a fake returning a failure
      getPetsProvider.overrideWithValue(_FakeGetPetsFailing()),
    ],
  );
  addTearDown(container.dispose);

  // Wait for the async build to settle, then assert
  await container.read(petListControllerProvider.future).then(
    (_) => fail('expected error'),
    onError: (e) => expect(e, isA<ServerFailure>()),
  );
});
```

For widget tests, wrap the tree in a `ProviderScope(overrides: [...])` and
override the controller provider directly to render loading/error/data states.
Test folders: `test/unit` (controllers/use cases), `test/widget`,
`test/integration`.

---

## 9. hooks_riverpod + flutter_hooks

Use hooks for **ephemeral, widget-local UI state and disposable controllers**;
use Riverpod for **shared/business state**. `HookConsumerWidget` gives you both
`ref` and hooks in one widget.

```dart
class AddPetScreen extends HookConsumerWidget {
  const AddPetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController();   // hook: auto-disposed
    final isSubmitting = useState(false);          // hook: local UI flag

    final controller = ref.read(petListControllerProvider.notifier);

    return PrimaryButton(
      loading: isSubmitting.value,
      onPressed: () async {
        isSubmitting.value = true;
        await controller.addPet(
          AddPetParams(name: nameCtrl.text),        // action → use case
        );
        isSubmitting.value = false;
      },
    );
  }
}
```

Rule of thumb: **text controllers, animation controllers, focus nodes, and
one-widget flags → hooks. Anything shared or domain-facing → a Riverpod
provider.**

---

## 10. Summary

- `Provider` for DI (`core/providers`); `AsyncNotifier` controllers for screen state
  (`presentation/controllers`); `FutureProvider` for read-only fetches;
  `StreamProvider` for Supabase Realtime and collar telemetry.
- Controllers call use cases and fold `Either<Failure, T>` into `AsyncValue`.
- `watch` to react, `read` for actions, `listen` for side effects, `select` to
  narrow rebuilds.
- Auto-dispose by default; `keepAlive` only for app-wide state.
- Override providers to test; use hooks for throwaway widget-local state.
