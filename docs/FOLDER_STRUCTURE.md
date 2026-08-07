# Folder Structure

This document is the map of the PetConnect AI codebase. It reproduces the full
directory tree and explains the purpose of every top-level and per-feature
folder, along with the naming conventions the project enforces.

The project is organized **feature-first** on top of **Clean Architecture** (see
`ARCHITECTURE.md`). Read this document together with that one: the tree here is
the physical expression of the layering described there.

---

## 1. The Tree

```
petconnect_ai/
├── lib/
│   ├── main.dart                     # Entry point → runs bootstrap()
│   ├── bootstrap.dart                # Init: dotenv, Supabase, Firebase, DI, error zone
│   ├── app.dart                      # Root MaterialApp.router + ProviderScope + theme
│   │
│   ├── l10n/                         # Localization ARB files + generated delegates
│   │
│   ├── core/                         # App-wide, framework wiring (no feature logic)
│   │   ├── config/                   # Env config, flavors, app-level settings
│   │   ├── error/                    # Failures (sealed) + Exceptions
│   │   ├── network/                  # Dio client, interceptors, connectivity checks
│   │   ├── providers/                # Riverpod DI: app-wide clients (Supabase, Dio, logger, connectivity)
│   │   ├── theme/                    # Design system entry (Material 3 + glassmorphic)
│   │   │   ├── tokens/               # Color, type, spacing, radius, elevation tokens
│   │   │   └── component_tokens/     # Per-component token maps (buttons, cards, …)
│   │   ├── utils/                    # Helpers, formatters, validators
│   │   │   └── extensions/           # Dart/Flutter extension methods
│   │   └── usecase/                  # Base UseCase<Type, Params> + NoParams
│   │
│   ├── router/                       # go_router: paths, names, guard, observer (top-level)
│   │
│   ├── shared/                       # Reusable across features
│   │   ├── domain/                   # entity.dart (base Entity + Paginated), repository.dart (marker)
│   │   ├── data/                     # model.dart (Model contract), datasource.dart (markers)
│   │   └── widgets/                  # Design-system widgets (token-driven)
│   │       ├── buttons/              # AppButton
│   │       ├── cards/                # AppCard
│   │       ├── inputs/               # AppTextField
│   │       ├── chips/                # AppChip
│   │       ├── loading/              # LoadingOverlay
│   │       ├── states/               # EmptyState, ErrorView, SkeletonLoader
│   │       ├── layout/               # SectionHeader
│   │       └── avatar/               # UserAvatar
│   │
│   └── features/                     # One folder per feature/portal
│       ├── auth/
│       ├── pet_owner/                # Primary portal
│       ├── veterinarian/
│       ├── volunteer_rescue/
│       ├── administrator/
│       └── community/
│           ├── data/
│           │   ├── datasources/      # Raw I/O (Supabase/Dio); throw typed Exceptions
│           │   ├── models/           # freezed + json_serializable; extend entities
│           │   └── repositories/     # Repository implementations (Exception → Failure)
│           ├── domain/
│           │   ├── entities/         # Immutable business objects (freezed)
│           │   ├── repositories/     # Abstract repository interfaces
│           │   └── usecases/         # Single-purpose actions → Either<Failure, T>
│           └── presentation/
│               ├── screens/          # Route-level composition
│               ├── widgets/          # Feature-local widgets
│               └── controllers/      # Riverpod AsyncNotifier/Notifier state
│
├── test/
│   ├── unit/                         # Use cases, repositories, datasources
│   ├── widget/                       # Widget + controller tests
│   └── integration/                  # End-to-end flows
│
├── docs/                             # This documentation
└── assets/
    ├── images/
    ├── icons/
    └── illustrations/
```

> Every feature under `lib/features/` follows the same
> `data / domain / presentation` shape shown expanded under `community/` above.
> The five other features (`auth`, `pet_owner`, `veterinarian`,
> `volunteer_rescue`, `administrator`) are identical in structure.

---

## 2. Application Entry Points (`lib/` root)

| File            | Responsibility |
|-----------------|----------------|
| `main.dart`     | The Flutter entry point. Keeps `void main()` tiny — it calls `bootstrap()`. |
| `bootstrap.dart`| Asynchronous initialization: load `flutter_dotenv`, initialize Supabase and Firebase, set up logging and the guarded error zone, and run the app inside a `ProviderScope`. |
| `app.dart`      | The root widget — `MaterialApp.router` wired to `go_router`, the theme (light master + dark), and localization. |

Splitting `main` / `bootstrap` / `app` keeps startup ordering explicit and
testable, and isolates the (necessarily messy) init sequence from the clean root
widget.

---

## 3. Top-Level Folders

### `lib/l10n/`
Localization sources (ARB files) and generated delegates. All user-facing copy
is externalized here rather than hardcoded in widgets.

### `lib/core/`
App-wide framework wiring that is **not** tied to any single feature. If it is a
cross-cutting concern (routing, theming, DI, error types, logging, network,
config), it lives here.

- `config/` — environment configuration and flavors (`flavor.dart`, `env.dart`,
  `app_config.dart`).
- `error/` — the sealed `Failure` hierarchy, typed `Exception`s, and the
  `FailureMapper` that translates one to the other at the repository boundary.
- `network/` — the Dio client (non-Supabase HTTP only), interceptors, and
  `connectivity_plus` checks.
- `providers/` — Riverpod dependency injection; `core_providers.dart` holds the
  app-wide providers (Supabase client, Dio client, connectivity, logger) and
  `theme_providers.dart` the theme-mode controller. Feature-scoped providers
  live in their own feature module.
- `theme/` — the "PetConnect AI Core" design system entry point.
  - `tokens/` — primitive design tokens (color, typography, spacing, radius,
    elevation). **All design values are centralized here; never hardcode them in
    widgets.**
  - `component_tokens/` — per-component token maps built from the primitives.
- `utils/` — helpers, formatters, and validators, with `extensions/` for
  extension methods.
- `usecase/` — the base `UseCase<Type, Params>` contract and `NoParams`.

### `lib/router/`
`go_router` configuration, kept top-level (a sibling of `core/`) because routing
spans every feature: `route_paths.dart` (paths + names for all four portals),
`route_guard.dart` (the redirect seam, permissive until Auth lands),
`route_observer.dart` (navigation logging), and `app_router.dart` (the graph).

External-system access has **no** dedicated `services/` layer. App-wide clients
(Supabase, Dio) are provided through `core/providers`; cross-cutting
infrastructure wrappers, when built, live under `core/`; feature-owned
integrations (AI assistant, smart collar) live in their feature module's
`data/datasources`.

### `lib/shared/`
Genuinely reusable building blocks used by more than one feature.

- `domain/` (`entity.dart`, `repository.dart`) and `data/` (`model.dart`,
  `datasource.dart`) — cross-feature base contracts.
- `widgets/` — the token-driven design-system widget library, grouped by kind:
  `buttons`, `cards`, `inputs`, `chips`, `loading`, `states`, `layout`,
  `avatar`.

### `lib/features/`
One folder per feature/portal. Each is a self-contained vertical slice with its
own `data`, `domain`, and `presentation` layers. Portals: `auth`, `pet_owner`
(primary), `veterinarian`, `volunteer_rescue`, `administrator`, and `community`.

### `test/`
Mirrors the architecture: `unit/` (use cases, repositories, datasources),
`widget/` (widgets and controllers), and `integration/` (end-to-end flows).

### `docs/` and `assets/`
Project documentation and static assets (`images`, `icons`, `illustrations`).

---

## 4. Per-Feature Structure

Inside any `features/<name>/` folder the three layers appear in full:

- **`data/`**
  - `datasources/` — raw I/O against Supabase or Dio; **throw typed Exceptions**.
  - `models/` — freezed + json_serializable; extend/map to domain entities.
  - `repositories/` — concrete implementations that translate Exceptions into
    `Failure`s and return `Either<Failure, T>`.
- **`domain/`**
  - `entities/` — immutable business objects (freezed), no serialization.
  - `repositories/` — abstract interfaces (the contract the data layer fulfills).
  - `usecases/` — single-purpose application actions returning
    `Either<Failure, T>`.
- **`presentation/`**
  - `screens/` — route-level composition.
  - `widgets/` — feature-local widgets.
  - `controllers/` — Riverpod `AsyncNotifier`/`Notifier` classes holding screen
    state and orchestrating use cases.

### Why feature-first

- **Cohesion.** Everything needed to understand or change a feature lives in one
  folder — you are not hopping between global `screens/`, `models/`, and
  `repositories/` directories.
- **Portal independence.** Four portals can be developed and reasoned about in
  parallel with minimal collisions.
- **Scalability.** New features are added by copying the same three-layer shape;
  the structure does not degrade as the app grows.
- **Clear ownership.** A feature folder maps naturally to a team or an area of
  responsibility.

---

## 5. Naming Conventions

- **Files & directories:** `snake_case` — e.g. `pet_repository_impl.dart`,
  `get_pets.dart`, `smart_collar/`.
- **Classes, enums, typedefs, extensions:** `PascalCase` — e.g.
  `PetRepositoryImpl`, `GetPets`, `Failure`.
- **Members, variables, functions:** `lowerCamelCase`.
- **Constants:** `lowerCamelCase` (Dart style), grouped in `core/constants`.
- **File suffixes reflect role:** `*_screen.dart`, `*_controller.dart`,
  `*_repository.dart` (abstract) vs `*_repository_impl.dart`, `*_model.dart`,
  `*_datasource.dart`, `*_usecase.dart` (or the action name, e.g. `get_pets.dart`).
- **Generated files:** freezed/json_serializable/riverpod produce
  `*.freezed.dart`, `*.g.dart` — never edited by hand.

Placement rule of thumb: if it is specific to one feature, it goes under that
feature; if it is reused across features, it goes in `shared/`; if it is
framework wiring, it goes in `core/`. See `CODING_STANDARDS.md`
for the full folder-placement rules.
