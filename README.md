# PetConnect AI

**Production-grade, AI-powered pet-care application** with 4 interconnected portals, smart collar integration, and community features.

---

## Status

**Foundation Phase Complete** — Clean Architecture skeleton, design system, routing, and core infrastructure are in place.

Authentication and feature screens are **not yet implemented**. The app currently boots to placeholder screens.

---

## Architecture

- **Clean Architecture** with feature-first organization
- **Riverpod** for state management and dependency injection (no `get_it`)
- **GoRouter** for declarative navigation
- **Supabase** for backend (Auth, Postgres + RLS, Storage, Realtime, Edge Functions)
- **Material 3 Expressive** design with Light/Dark themes
- **Inter** typography, `dartz` functional error handling, `freezed` + `json_serializable` codegen

---

## Portals

1. **Pet Owner** (primary) — pet profiles, health records, AI assistant, smart collar dashboard, community
2. **Veterinarian** — appointments, patient records, telemetry review
3. **Volunteer & Rescue** — rescue case management, lost-pet map, alerts
4. **Administrator** — user management, moderation, analytics

---

## Design System

The **PetConnect AI Core** design system is frozen and authoritative. All values live in `lib/core/theme/`:

- **Tokens**: `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_elevation.dart`, `app_durations.dart`, `app_breakpoints.dart`, `app_icon_sizes.dart`
- **Component tokens**: `button_tokens.dart`, `card_tokens.dart`, `chip_tokens.dart`, `input_tokens.dart`
- **Themes**: `AppTheme.light` / `AppTheme.dark` (Material 3)
- **Portal themes**: each portal can have its own accent (currently all share the core palette)

Widgets consume theme via `Theme.of(context)` — never hardcode values.

---

## Project Structure

```
lib/
├── core/
│   ├── config/           # Env, flavor, AppConfig
│   ├── error/            # Exceptions, Failures, mapper
│   ├── network/          # Dio client, network info
│   ├── providers/        # Riverpod DI (config, logger, network, Supabase, theme)
│   ├── theme/            # Design system (tokens, schemes, ThemeData)
│   ├── usecase/          # UseCase base contracts
│   └── utils/            # Extensions, validators, logger, typedefs
├── features/
│   ├── auth/             # (placeholder — implement during Auth phase)
│   ├── pet_owner/        # (placeholder — implement during Pet Owner phase)
│   ├── veterinarian/     # (placeholder)
│   ├── volunteer_rescue/ # (placeholder)
│   └── administrator/    # (placeholder)
├── router/
│   ├── app_router.dart   # Complete GoRouter with all 4 portals
│   ├── route_paths.dart  # Route constants
│   ├── route_guard.dart  # Auth redirect logic (permissive until Auth phase)
│   └── route_observer.dart
├── shared/
│   ├── data/             # Model, DataSource base contracts
│   ├── domain/           # Entity, Repository base contracts
│   └── widgets/          # PlaceholderScreen (foundation only)
├── app.dart              # Root widget
├── bootstrap.dart        # Startup: .env load, Supabase init, ProviderScope
└── main.dart             # Entry point
```

---

## Setup

### Prerequisites

- **Flutter 3.44.9** / Dart 3.12.2 (or later stable)
- **Git**
- A **Supabase project** (URL + anon key)
- (Optional) **Google Maps API key**, **Firebase project** for FCM

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Antony0610/Pet_Connect_Ai.git
   cd Pet_Connect_Ai/petconnect_ai
   ```

2. **Generate native platform folders:**

   ```bash
   flutter create --platforms=android,ios .
   ```

   This creates the `android/` and `ios/` directories without overwriting the existing Dart code.

3. **Install dependencies:**

   ```bash
   flutter pub get
   ```

4. **Configure environment:**

   Copy `.env.example` to `.env` and fill in your keys:

   ```bash
   cp .env.example .env
   ```

   At minimum, set:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

5. **Run code generation:**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   (No generated files exist yet; this will be needed once feature models land.)

6. **Run the app:**

   ```bash
   flutter run
   ```

   The app boots to a splash placeholder. All routes in `/owner`, `/vet`, `/rescue`, `/admin` are wired but show placeholders.

---

## What's Next

### Remaining before Authentication

- [ ] Shared component library (buttons, cards, inputs, dialogs, etc.) — **Phase 6**
- [ ] Project standards doc (linting already configured) — **Phase 7**
- [ ] Validation report — **Phase 8**

Once the foundation is approved, the **Authentication feature** implements:
- Login / Register / Forgot Password screens
- Role selection
- Session management via Supabase Auth
- Route guards in `route_guard.dart`

After Auth, each portal is built in sequence (Pet Owner → Vet → Rescue → Admin), following the frozen Stitch design.

---

## Documentation

See `/docs` for:
- `ARCHITECTURE.md` — Clean Architecture layers, DI, feature-first structure
- `FOLDER_STRUCTURE.md` — Directory conventions
- `CODING_STANDARDS.md` — Style, linting, naming
- `STATE_MANAGEMENT.md` — Riverpod patterns
- `API_CONVENTIONS.md` — Repository, data source, DTO↔entity mapping
- `DATABASE_OVERVIEW.md` — Supabase schema, RLS, storage buckets
- `DEPLOYMENT_PLAN.md` — Flavors, CI/CD, release process
- `AI_ARCHITECTURE.md` — Gemini + RAG via Edge Functions
- `SMART_COLLAR_ARCHITECTURE.md` — ESP32 integration, telemetry ingest
- `N8N_AUTOMATION_PLAN.md` — Webhook-driven workflows

---

## Contributing

This is a production-focused project. All code follows:
- **Strict linting** (configured in `analysis_options.yaml`)
- **Clean Architecture** (domain ← data, presentation → domain)
- **Design system tokens** (no hardcoded values in widgets)
- **Functional error handling** (`Either<Failure, T>` via `dartz`)

Commits should be small, logical, and have clear messages.

---

## License

[Specify license here]

---

## Contact

[Specify contact/maintainer info here]
