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
│   │   ├── constants/                # App constants, keys, durations, enums
│   │   ├── di/                       # Riverpod DI — providers.dart (root providers)
│   │   ├── error/                    # Failures (sealed) + Exceptions
│   │   ├── logging/                  # logger setup, log helpers
│   │   ├── network/                  # Dio client, interceptors, connectivity checks
│   │   ├── providers/                # Riverpod DI: app-wide clients (Supabase, Dio, logger)
│   │   ├── router/                   # go_router config, routes, guards, redirects
│   │   ├── theme/                    # Design system entry (Material 3 + glassmorphic)
│   │   │   ├── tokens/               # Color, type, spacing, radius, elevation tokens
│   │   │   └── component_tokens/     # Per-component token maps (buttons, cards, …)
│   │   ├── utils/                    # Helpers, formatters, validators
│   │   │   └── extensions/           # Dart/Flutter extension methods
│   │   └── usecase/                  # Base UseCase<Type, Params> + NoParams
│   │
│   ├── shared/                       # Reusable across features
│   │   ├── domain/
│   │   │   └── entities/             # Cross-feature domain entities
│   │   ├── data/
│   │   │   └── models/               # Cross-feature data models
│   │   └── presentation/
│   │       └── widgets/              # Design-system widgets (token-driven)
│   │           ├── buttons/
│   │           ├── cards/
│   │           ├── inputs/
│   │           ├── chips/
│   │           ├── feedback/         # Snackbars, dialogs, loaders, empty/error states
│   │           ├── navigation/       # Nav bars, tabs, app bars
│   │           ├── data_display/     # Lists, tiles, tables, stats
│   │           └── layout/           # Scaffolds, spacers, responsive layout
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

- `config/` — environment configuration and flavors.
- `constants/` — shared constants and enums.
- `di/` — Riverpod dependency injection; `providers.dart` holds the root
  providers (services, repositories, use cases).
- `error/` — the sealed `Failure` hierarchy and typed `Exception`s.
- `logging/` — `logger` configuration and helpers.
- `network/` — the Dio client (non-Supabase HTTP only), interceptors, and
  `connectivity_plus` checks.
- `router/` — `go_router` configuration, route definitions, and auth guards.
- `theme/` — the "PetConnect AI Core" design system entry point.
  - `tokens/` — primitive design tokens (color, typography, spacing, radius,
    elevation). **All design values are centralized here; never hardcode them in
    widgets.**
  - `component_tokens/` — per-component token maps built from the primitives.
- `utils/` — helpers, formatters, and validators, with `extensions/` for
  extension methods.
- `usecase/` — the base `UseCase<Type, Params>` contract and `NoParams`.

### `lib/services/`
Injectable wrappers around external systems, each exposed through a Riverpod
provider so datasources depend on the wrapper, not the raw SDK.

- `supabase/` — the Supabase client and access to Auth, Postgres, Storage,
  Realtime, and Edge Functions.
- `auth/` — session and auth-state service on top of Supabase Auth.
- `notifications/` — `firebase_messaging` + `flutter_local_notifications`.
- `location/` — `google_maps_flutter`, geolocation, and permissions.
- `storage/` — media upload/download against Supabase Storage.
- `ai/` — Gemini API plus RAG (local embeddings + Supabase pgvector).
- `smart_collar/` — the ESP32 collar: WiFi (default) and BLE (setup), GPS
  tracking, geofence/safe-zones, lost mode, and activity/battery telemetry.

### `lib/shared/`
Genuinely reusable building blocks used by more than one feature.

- `domain/entities/` and `data/models/` — cross-feature domain and data types.
- `presentation/widgets/` — the token-driven design-system widget library,
  grouped by kind: `buttons`, `cards`, `inputs`, `chips`, `feedback`,
  `navigation`, `data_display`, `layout`.

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
framework wiring, it goes in `core/` or `services/`. See `CODING_STANDARDS.md`
for the full folder-placement rules.
