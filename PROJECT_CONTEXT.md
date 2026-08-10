# PetConnect AI — PROJECT_CONTEXT.md

> **Single source of truth for future Claude Code conversations.**
> This document describes the repository as it exists today so that any future
> session can continue development **without the previous chat history**. It is
> descriptive documentation only — it changes no code and mandates no new work.
>
> _Generated: 2026-08-08. Reflects `master` @ `15cd917` (tag `v1.0.1` + 19 commits)._

---

## 1. Project Overview

| Field | Value |
|---|---|
| **Project name** | PetConnect AI (`petconnect_ai`) |
| **Purpose** | A four-portal pet-care platform: Pet Owners manage pets, a Health Passport, an AI care assistant, and a GPS Smart Collar; Veterinarians, Volunteer/Rescue orgs, and Administrators each get a dedicated portal. |
| **Overall architecture** | Clean Architecture (data / domain / presentation) with feature-first organization, Riverpod DI + state, GoRouter navigation, Supabase backend. |
| **Flutter / Dart** | Dart SDK constraint `>=3.12.0 <4.0.0` (Dart 3, Flutter stable channel — see CI). |
| **Main packages** | `flutter_riverpod` ^2.6.1, `go_router` ^14.6.2, `supabase_flutter` ^2.9.0, `dio` ^5.7.0, `freezed`/`json_serializable`, `google_fonts` ^6.2.1, `dartz` ^0.10.1, `google_maps_flutter` ^2.10.0, `firebase_messaging`/`firebase_core`, `flutter_secure_storage`, `flutter_dotenv`. |
| **Repository URL** | https://github.com/Antony0610/Pet_Connect_Ai.git |
| **Current branch** | `master` |
| **Declared version** | `pubspec.yaml` → `1.0.0+1` |
| **Latest git tag** | `v1.0.1` (earlier tag: `v1.0.0`) |
| **HEAD** | `15cd917` = `v1.0.1-19-g15cd917` |

**Portal status at a glance:** Pet Owner is the primary, richly-built portal
(~85–90%). Vet, Volunteer/Rescue, and Administrator portals are fully routed but
every screen is a `PlaceholderScreen` (~0% UI).

---

## 2. Design Authority (FROZEN — do not violate)

The visual design is **frozen**. These rules override any instinct to "improve"
the UI:

- **Stitch Light Theme is the ONLY design authority.** The Stitch MCP Light
  design (captured in the token layer) is the single source of truth for color,
  type, spacing, radius, and elevation.
- **Dark Theme is always derived from Light.** Dark is a role-mapped counterpart
  of Light, never an independent aesthetic. (Mechanically both schemes are
  hand-authored `const ColorScheme`s fed through one shared builder — see §8.)
- **Never redesign.** Do not restyle existing screens, invent new visual
  languages, or "modernize" what is already built.
- **Never simplify workflows.** Every screen and step that exists is intentional;
  do not collapse multi-step flows into shortcuts.
- **Never merge screens.** Each route is a distinct destination; keep them
  separate even when they look similar.
- **Reuse `ThemeData` and Design Tokens.** All styling flows from
  `Theme.of(context)` / `context.colorScheme` and the `app_*` token classes.
  Never hardcode a color, spacing value, radius, font, or shadow.

**AI-content rule (frozen):** AI-generated content is always presented inside the
signature **gradient-bordered card** (`AiGradientBorderCard`), with
source-attribution chips (`AiSourceChip`) and a confidence badge
(`AiConfidenceBadge`) where applicable. This is a design contract, not a
suggestion.

---

## 3. Project Architecture

**Clean Architecture, feature-first.**

```
lib/
├── main.dart          # entry → bootstrap()
├── bootstrap.dart     # .env → AppConfig → Supabase.init → ProviderScope(overrides)
├── app.dart           # MaterialApp.router (theme + router from providers)
│
├── core/              # cross-cutting infrastructure (no feature logic)
│   ├── config/        # flavor, env, app_config
│   ├── error/         # exceptions, failures (sealed), failure_mapper
│   ├── network/       # dio_client, network_info
│   ├── providers/     # core_providers (DI), theme_providers
│   ├── theme/         # tokens/, component_tokens/, schemes, AppTheme, portal_theme
│   ├── usecase/       # UseCase base contracts
│   └── utils/         # extensions/, logger, validators, typedefs
│
├── features/<feature>/
│   ├── data/          # models (DTOs), datasources, repository impls
│   ├── domain/        # entities, repository contracts, usecases
│   └── presentation/  # screens/, widgets/, providers (Riverpod)
│
├── router/            # route_paths, route_guard, route_observer, app_router
├── shared/            # data/ domain/ base classes + widgets/ component library
└── l10n/              # ARB files (en, ar) — prepared, NOT enabled
```

**Dependency flow (strict, inward-pointing):**

```
presentation ──▶ domain ◀── data
     │             ▲          │
     └── providers ┘          └── core (config/error/network/utils)
```

- **presentation** depends on **domain** (entities, usecases) and reads state via
  Riverpod providers. It never imports `data` directly.
- **data** implements **domain** repository contracts; maps `Exception` → sealed
  `Failure` via `failure_mapper`.
- **domain** depends on nothing outward — pure Dart, `Equatable` entities,
  `Either<Failure, T>` (dartz) return types.
- **core** is shared by all layers but knows nothing about features.
- **Riverpod** is the DI mechanism: `core_providers.dart` exposes
  `appConfigProvider`, `loggerProvider`, `supabaseClientProvider`,
  `dioProvider`, etc.; each feature layers its own providers on top.

**Backend:** Supabase (Auth, Postgres + RLS, Storage, Realtime, Edge Functions).
`dio` is reserved for non-Supabase HTTP. See `docs/` for the deep-dive design
notes (`ARCHITECTURE.md`, `DATABASE_OVERVIEW.md`, `AI_ARCHITECTURE.md`,
`SMART_COLLAR_ARCHITECTURE.md`, `N8N_AUTOMATION_PLAN.md`, etc.).

---

## 4. Foundation Summary

Foundation shipped **82 files across 8 phases** and is production-ready. It is
captured in detail in [`FOUNDATION_COMPLETE.md`](FOUNDATION_COMPLETE.md).

- **Theme** — full Material 3 `ThemeData` for Light and Dark built by one shared
  `AppTheme._buildTheme`; all M3 component themes configured.
- **Tokens** — `app_colors`, `app_typography` (Inter via google_fonts),
  `app_spacing` (4px base), `app_radius`, `app_elevation`, `app_durations`,
  `app_breakpoints`, `app_icon_sizes`; plus `component_tokens/`
  (button/card/input/chip).
- **Shared widgets** — buttons, cards, chips, inputs, avatars, section header,
  loading overlay, empty/error/skeleton states, placeholder screen (see §7).
- **Routing** — complete GoRouter graph for all four portals with stable
  paths/names; permissive `RouteGuard` (returns `null`, ready for auth gating).
- **Localization** — ARB templates (`app_en.arb`, `app_ar.arb`) and `l10n.yaml`
  are **prepared but intentionally not enabled** (to avoid blocking `pub get`);
  see `lib/l10n/README.md` for the enablement checklist.
- **CI** — `.github/workflows/ci.yml` runs on push/PR to `master`: sets up
  Flutter stable, seeds `.env` from `.env.example`, `flutter pub get`,
  `dart format --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`,
  `flutter test`.
- **Testing** — unit/widget tests run in CI; current suite = **29 passing**.
- **Git workflow** — small logical commits, pushed after each step; work tagged
  at Foundation milestones (`v1.0.0`, `v1.0.1`).

**Important Foundation fixes / decisions:**
- Removed `flutter_hooks`/`hooks_riverpod` from active use (commit `35710c4`);
  standardized on plain `flutter_riverpod`.
- `dart format` normalization pass (`1042d9f`).
- Folder-structure sync + Foundation QA pass (`cd0164e`, `ff79ff2`).
- Stabilized to `v1.0.1` and scaffolded auth (`c79ffb3`).
- CI made **info-lint tolerant**: the codebase deliberately uses **relative
  imports within `lib/`**, which trips `always_use_package_imports` (info only);
  `--no-fatal-infos` keeps the build green. This is intentional and repo-wide.

---

## 5. Authentication Summary

Auth is **end-to-end complete** (UI + Supabase wiring) for the sign-up / verify /
sign-in journey.

**Screens** (`features/auth/presentation/screens/`):
- `SplashScreen` — resolves start destination via `splashDestinationProvider`.
- `OnboardingScreen` — 4-page intro.
- `LoginScreen` — email/password sign-in.
- `CreateAccountScreen` — registration (full name, email, password, optional
  phone).
- `RoleSelectionScreen` — selects portal (`selectedPortalProvider`, default
  `petOwner`).
- `OtpVerificationScreen` — **6-digit email OTP** (final implementation).
- `WelcomeSuccessScreen` — post-verification success.
- `InitialPetSetupScreen` — first-pet capture for new owners.

**Domain:** `AuthSession` entity; `AuthRepository` + `OnboardingRepository`
contracts; usecases `SignInWithPassword`, `CreateAccount`, `VerifyEmailOtp`,
`ResendEmailOtp`, `GetCurrentSession`, `CompleteOnboarding`,
`IsOnboardingComplete`.

**Data:** `AuthRemoteDataSource(Impl)`, `OnboardingLocalDataSource(Impl)`,
`AuthSessionModel`, `AuthRepositoryImpl`, `OnboardingRepositoryImpl`.

**Providers:** `authRemoteDataSourceProvider`, `onboardingLocalDataSourceProvider`,
`authRepositoryProvider`, `onboardingRepositoryProvider`,
`getCurrentSessionProvider`, `isOnboardingCompleteProvider`,
`completeOnboardingProvider`, `signInWithPasswordProvider`,
`createAccountProvider`, `verifyEmailOtpProvider`, `resendEmailOtpProvider`,
`pendingVerificationEmailProvider` (`StateProvider<String?>`),
`selectedPortalProvider` (`StateProvider<AppPortal>`),
`splashDestinationProvider` (`FutureProvider<String>`).

**Navigation:** auth routes are top-level (`/login`, `/register`,
`/role-selection`, `/verify-otp`, `/welcome`, `/pet-setup`);
`/forgot-password` is still a `PlaceholderScreen`.

**OTP flow (final, 6-digit) — Supabase `OtpType.signup`:**
- Sign-up → `auth.signUp(email, password, data: {full_name, phone?})`.
- Verify → `auth.verifyOTP(email, token, type: OtpType.signup)` with
  `_codeLength = 6`.
- Resend → `auth.resend(type: OtpType.signup, email)`.
- Session read → `auth.currentSession`; Login → `auth.signInWithPassword`.

**Route guard:** `RouteGuard.redirect` is currently permissive (returns `null`).
The `TODO(auth)` marks where session/role gating will be added **without touching
`app_router.dart`**.

---

## 6. Pet Owner Summary

The Pet Owner portal uses **plain `context.goNamed` navigation** (NOT a
`StatefulShellRoute`). All owner screens live under
`features/pet_owner/presentation/`. Sub-feature routes (Health/AI/Collar) are
**pushed routes with back-button app bars**, not bottom-tab destinations.

### Core
- **Screens:** `HomeDashboardScreen`, `MyPetsListScreen`, `AddPetScreen`,
  `PetProfileDetailScreen`, `EditPetProfileScreen`, `PetSettingsScreen`,
  `DeletePetConfirmationScreen`, `PetMediaGalleryScreen`, `NotificationsScreen`,
  `ProfileScreen`, `SettingsScreen`, `ActivateLostModeScreen`.
- **Widgets (`widgets/`, barrel `owner_widgets`… + libs):** `OwnerScaffold`
  (plain Scaffold + goNamed nav), `OwnerBottomNavBar` (`OwnerTab` enum:
  home/pets/community/notifications/profile), `OwnerGlassAppBar` /
  `OwnerAppBarBrand` / `OwnerAppBarAction`, `OwnerActionFab`, `OwnerAiFab`
  (56×56 emerald `auto_awesome`).
- **Routes:** `/owner`, `/owner/pets` (+ `add`, `:petId` + `edit`/`settings`/
  `delete`/`gallery`), `/owner/notifications`, `/owner/profile`,
  `/owner/settings`, `/owner/lost-mode`. `/owner/search` = **Placeholder**.
- **Shared:** `AppCard`, `AppButton`, `GlassCard`, `UserAvatar`/`PetAvatar`,
  `SectionHeader`, state widgets.

### Health Passport
- **Screens:** `HealthPassportDashboardScreen`, `MedicalHistoryRecordScreen`,
  `VaccinationOverviewScreen`, `HealthPassportTimelineScreen`,
  `GrowthWeightAnalyticsScreen`.
- **Widgets (`health_widgets.dart`, `library;`):** `healthAppBar`,
  `HealthPetAvatar`, `HealthAccentButton`, `HealthCircleIcon`,
  `HealthCategoryChip`, `HealthMetaLine`, `HealthRecordRow`, `HealthCardHeader`,
  `HealthEmptyBox` (+ `kHealthPetPhotoUrl`).
- **Routes:** `/owner/health` + `medical`, `vaccinations`, `timeline`, `growth`.

### AI Hub
- **Screens:** `AiHubDashboardScreen`, `AiAssistantChatScreen`,
  `AiHealthInsightsScreen`, `AiRecommendationsScreen`, `AiReportsScreen`,
  `AiHistoryScreen`.
- **Widgets (`ai_widgets.dart`, `library;`):** `aiAppBar`, `AiCircleIcon`,
  `AiGradientBorderCard`, `AiConfidenceBadge`, `AiSourceChip`, `AiListTile`.
- **Routes:** `/owner/ai` + `chat`, `insights`, `recommendations`, `reports`,
  `history`.
- **Integrations:** UI is presentation-only today (curated sample data +
  snackbars); designed to bind to a live AI service (Gemini + RAG per
  `docs/AI_ARCHITECTURE.md`) later. All AI output already sits in the
  gradient-bordered card with source chips.

### Smart Collar
- **Screens:** `SmartCollarDashboardScreen`, `SmartCollarTrackingScreen`,
  `SmartCollarActivityScreen`, `SmartCollarGeofenceScreen`,
  `SmartCollarDiagnosticsScreen`, `SmartCollarSettingsScreen`.
- **Widgets (`collar_widgets.dart`, `library;`):** `collarAppBar`,
  `CollarStatTile`, `CollarMetricRing`, `CollarActionTile`, `CollarMapPreview`,
  `CollarLivePill` (+ `kCollarPetPhotoUrl`, `kCollarMapUrl`).
- **Routes:** `/owner/collar` + `tracking`, `activity`, `geofence`,
  `diagnostics`, `settings`.
- **Integrations:** map preview is a static image placeholder; designed for
  `google_maps_flutter` + ESP32 collar telemetry (`docs/SMART_COLLAR_ARCHITECTURE.md`).

### Community — **PENDING**
- Only a `PlaceholderScreen` at `/owner/community` (route name
  `ownerCommunity`). No screens, widgets, domain, or data yet. **This is the next
  Pet Owner feature to build.**

---

## 7. Shared Component Library

`lib/shared/widgets/` — barrel `widgets.dart` (12 exports). Reuse these before
building anything new.

| Widget | Use it when… |
|---|---|
| `AppButton` (factories `.filled` / `.outlined` / `.text`; sizes small/medium/large; loading state) | Any button. **No `.tonal` factory** — pass `variant` for tonal. |
| `AppCard` (`isOutlined`, `backgroundColor`, `onTap`) | Standard surface container / tappable card. |
| `GlassCard` (`blurSigma=20`, `borderRadius=brSection`, `clipContent`) | Glassmorphic panels (app bars, overlays, premium surfaces). |
| `AppChip` (filled / outlined) | Static chips / tags. (For choice/filter/action chips use Material `ChoiceChip`/`ActionChip` styled with tokens, as the AI screens do.) |
| `AppTextField` (Stateful; size variants; clearable) | Any text input. |
| `UserAvatar` / `PetAvatar` | User or pet imagery with fallback initials. |
| `SectionHeader` | Titled section with optional trailing action. |
| `LoadingOverlay` (+ static `show`) | Full-screen blocking spinner. |
| `EmptyState` | Empty collection / zero-results. |
| `ErrorView` | Error + retry affordance. |
| `SkeletonLoader` (+ `.circle`) | Shimmer placeholders while loading. |
| `PlaceholderScreen` | Stand-in for unbuilt routes (title/subtitle). |

**Base classes** (`shared/domain`, `shared/data`): `Entity extends Equatable` +
`Paginated<T>`; `Repository` marker; `Model` (toJson); `DataSource` /
`RemoteDataSource` / `LocalDataSource`; `UseCase` contracts in `core/usecase`.

**Feature-scoped primitive libraries** (imported directly, NOT in the shared
barrel and NOT in the owner-widgets barrel): `health_widgets.dart`,
`ai_widgets.dart`, `collar_widgets.dart`. Reuse the matching library when
building within that sub-feature so new screens inherit the frozen look.

---

## 8. Theme System

All theming lives in `lib/core/theme/`. Barrel: `theme.dart`.

**Token categories:**
- **`app_colors.dart`** — seed `0xFF6750A4`; per-portal accents
  (petOwner `0xFF10B981` emerald, veterinarian `0xFF2563EB`, volunteerRescue
  `0xFFF97316`, administrator `0xFF4F378A`); full light/dark/fixed roles; status
  colors (success/warning/info); glass/divider/border overlays.
- **`app_typography.dart`** — Inter (`GoogleFonts.interTextTheme`); weights
  regular/medium/semiBold/bold; full M3 type scale.
- **`app_spacing.dart`** — 4px base (`base4`, `xs8`, `sm12`, `md16`, `lg24`,
  `xl32`, `xxl48`); page margins (mobile/tablet/desktop); ready-made gap
  `SizedBox`es (`vGapMd`, `hGapSm`, …).
- **`app_radius.dart`** — `sm4`…`full9999`; semantic `brCard16`, `brSection24`,
  `brPill`, `brModal32`.
- **`app_elevation.dart`** — `level0`–`level5`; shadow lists; `card(Brightness)`,
  `soft(Brightness)`.
- **`app_durations.dart`** — motion `Duration` + `Curve` tokens.
- **`app_breakpoints.dart`** — `mobile 600`, `tablet 1024`, `desktop 1440`,
  `maxContentWidth 1200`; `ScreenSize` enum.
- **`app_icon_sizes.dart`** — `xs16`, `sm20`, `md24`, `lg32`, `xl40`, `xxl48`.
- **`component_tokens/`** — `button_tokens`, `card_tokens`, `input_tokens`,
  `chip_tokens`.

**How Light and Dark are generated (read carefully):**
- `app_color_scheme.dart` declares **two independent hand-authored
  `const ColorScheme`s** — `AppColorScheme.light` and `AppColorScheme.dark`.
  They are **NOT** produced by `ColorScheme.fromSeed`, and Dark is **not**
  computed at runtime. Conceptually Dark is the role-mapped counterpart of the
  frozen Light (per the design authority), but mechanically both are static.
- `app_theme.dart` exposes `AppTheme.light` / `AppTheme.dark`, both delegating to
  one private `_buildTheme({colorScheme, brightness})`. The builder branches on
  `isDark` **only** for the elevation-overlay and card `surfaceTint` details;
  every other value comes from the shared token classes. **One builder → both
  themes.**
- `app.dart` wires `theme: AppTheme.light`, `darkTheme: AppTheme.dark`,
  `themeMode: themeModeProvider`.

**Per-portal accent system** (`portal_theme.dart`):
- `enum AppPortal { petOwner, veterinarian, volunteerRescue, administrator }`.
- `PortalPalette.fromSeed`: when `seed == AppColors.seed` it uses the
  authoritative `AppColorScheme`; otherwise falls back to `ColorScheme.fromSeed`.
- `PortalPalettes` registry currently maps **all four portals to the shared Core
  seed**, so per-portal seed divergence is wired but **dormant** — every portal
  resolves to the same Core scheme today. Accent access:
  `PortalPalettes.of(AppPortal.petOwner).accent` /
  `.accentContainer(brightness)` / `.onAccentContainer(brightness)`.
- `ThemeModeNotifier extends Notifier<ThemeMode>` (`build` → `system`; `set`,
  `toggle`; persistence is a TODO); exposed as `themeModeProvider`.

**Responsive pattern used by every screen:** a static
`_horizontalMargin(width)` (mobile/tablet/desktop margins) +
`ConstrainedBox(maxWidth: AppBreakpoints.maxContentWidth)` +
`isWide = width >= AppBreakpoints.tablet` for grid column counts.

---

## 9. Routing

`lib/router/` — `route_paths.dart` (constants), `app_router.dart` (graph),
`route_guard.dart` (redirect), `route_observer.dart` (logging).

- `routerProvider` (Riverpod `Provider<GoRouter>`), `initialLocation = '/'`,
  `debugLogDiagnostics = appConfig.isDebuggable`, observer =
  `AppRouteObserver(logger)`, `redirect = RouteGuard.redirect`, `errorBuilder`
  → `PlaceholderScreen('Not Found')`.
- Route **names** mirror path leaves and are declared in `RouteNames`; call sites
  use `context.goNamed(RouteNames.x)` — never string literals.

**Complete route tree** (⛔ = still a `PlaceholderScreen`):

```
/                         splash              → SplashScreen
/onboarding               onboarding          → OnboardingScreen

/login                    login               → LoginScreen
/register                 register            → CreateAccountScreen
/forgot-password          forgotPassword      → ⛔ Forgot Password
/role-selection           roleSelection       → RoleSelectionScreen
/verify-otp               otpVerification     → OtpVerificationScreen
/welcome                  welcomeSuccess      → WelcomeSuccessScreen
/pet-setup                initialPetSetup     → InitialPetSetupScreen

/owner                    ownerHome           → HomeDashboardScreen
  notifications           ownerNotifications  → NotificationsScreen
  search                  ownerSearch         → ⛔ Search
  pets                    ownerPets           → MyPetsListScreen
    add                   ownerPetAdd         → AddPetScreen
    :petId                ownerPetDetail      → PetProfileDetailScreen
      edit                ownerPetEdit        → EditPetProfileScreen
      settings            ownerPetSettings    → PetSettingsScreen
      delete              ownerPetDelete      → DeletePetConfirmationScreen
      gallery             ownerPetGallery     → PetMediaGalleryScreen
  health                  ownerHealth         → HealthPassportDashboardScreen
    medical               ownerHealthMedical        → MedicalHistoryRecordScreen
    vaccinations          ownerHealthVaccinations   → VaccinationOverviewScreen
    timeline              ownerHealthTimeline       → HealthPassportTimelineScreen
    growth                ownerHealthGrowth         → GrowthWeightAnalyticsScreen
  ai                      ownerAiAssistant    → AiHubDashboardScreen
    chat                  ownerAiChat            → AiAssistantChatScreen
    insights              ownerAiInsights        → AiHealthInsightsScreen
    recommendations       ownerAiRecommendations → AiRecommendationsScreen
    reports               ownerAiReports         → AiReportsScreen
    history               ownerAiHistory         → AiHistoryScreen
  collar                  ownerCollar         → SmartCollarDashboardScreen
    tracking              ownerCollarTracking     → SmartCollarTrackingScreen
    activity              ownerCollarActivity     → SmartCollarActivityScreen
    geofence              ownerCollarGeofence     → SmartCollarGeofenceScreen
    diagnostics           ownerCollarDiagnostics  → SmartCollarDiagnosticsScreen
    settings              ownerCollarSettings     → SmartCollarSettingsScreen
  lost-mode               ownerLostMode       → ActivateLostModeScreen
  community               ownerCommunity      → ⛔ Community
  profile                 ownerProfile        → ProfileScreen
  settings                ownerSettings       → SettingsScreen

/vet                      vetHome             → ⛔ Vet Home
  appointments            vetAppointments     → ⛔ Appointments
  patients                vetPatients         → ⛔ Patients
    :patientId            vetPatientDetail    → ⛔ Patient Detail
  profile                 vetProfile          → ⛔ Vet Profile

/rescue                   rescueHome          → ⛔ Rescue Home
  cases                   rescueCases         → ⛔ Rescue Cases
    :caseId               rescueCaseDetail    → ⛔ Case Detail
  map                     rescueMap           → ⛔ Rescue Map
  profile                 rescueProfile       → ⛔ Rescue Profile

/admin                    adminHome           → ⛔ Admin Home
  users                   adminUsers          → ⛔ User Management
  moderation              adminModeration     → ⛔ Moderation
  analytics               adminAnalytics      → ⛔ Analytics

/404                      (RoutePaths.notFound; handled by errorBuilder)
```

---

## 10. Current Repository Status

**Completed modules:**
- Foundation (theme, tokens, shared widgets, routing graph, DI, CI, docs).
- Authentication (UI + Supabase, 6-digit OTP).
- Pet Owner → Core, Health Passport, AI Hub, Smart Collar.

**Pending modules:**
- Pet Owner → **Community** (placeholder only).
- **Forgot Password** flow (placeholder).
- Owner **Search** (placeholder).
- **Veterinarian**, **Volunteer/Rescue**, **Administrator** portals (all
  placeholder screens; routes defined).

**Known TODOs / technical debt:**
- `RouteGuard.redirect` returns `null` — real session/role gating not yet wired
  (`TODO(auth)`).
- `ThemeModeNotifier` persistence is a TODO (theme choice not saved across
  launches).
- AI Hub and Smart Collar screens render **curated sample data** and emit
  snackbars; no live AI service or collar telemetry binding yet.
- Per-portal accent divergence is wired but dormant (all portals share the Core
  seed).
- Localization is prepared but **not enabled**.
- Repo-wide **relative imports** trip `always_use_package_imports` (info-level);
  CI runs `--no-fatal-infos` by design.

**Known assumptions:**
- Supabase project + `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional
  `GOOGLE_MAPS_API_KEY`, `AI_EDGE_FUNCTION_URL`) are provided at runtime; `.env`
  is gitignored and seeded from `.env.example` in CI.
- Analyzer surfaces a large count of **info-level** `always_use_package_imports`
  lints; these are expected and are NOT to be "fixed" wholesale.

---

## 11. Implementation Rules (permanent)

1. **Never hardcode** colors, spacing, radii, typography, elevation, durations,
   or icon sizes — always use the `app_*` token classes / `context.colorScheme`.
2. **Never bypass `ThemeData`.** Style through `Theme.of(context)` and the token
   layer; one widget tree must serve both Light and Dark.
3. **Reuse shared + feature-scoped widgets** (§7) before writing new ones.
4. **Read the Stitch design first.** Before building any screen, consult the
   frozen Stitch Light source; match it exactly. Never redesign / simplify /
   merge screens.
5. **AI content is always gradient-bordered** (`AiGradientBorderCard`) with
   source chips + confidence badge.
6. **Route via names**: `context.goNamed(RouteNames.x)`; declare new paths/names
   in `route_paths.dart`; keep existing paths/names stable.
7. **Respect Clean Architecture layering** (presentation → domain ← data; core is
   shared). Return `Either<Failure, T>`; map exceptions in the data layer.
8. **Validate only after completing a feature** — run `flutter analyze` +
   `flutter test`; fix only issues **introduced by that feature** (do not touch
   the pre-existing repo-wide info lints).
9. **Commit logical milestones** with descriptive messages
   (`Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`).
10. **Push after each feature** — small commits, pushed after every step; **stop
    on push failure**. (Exception: an explicit "documentation only / do not
    commit" instruction overrides auto-push.)
11. **Secrets never committed.** `.env` and `.mcp.json` stay untracked; the
    Stitch API key in `.mcp.json` is a plaintext secret pending rotation — never
    echo it.
12. **After finishing a module, STOP for review** before starting the next
    feature unless told to continue.

---

## 12. Git History Summary

Branch `master`; remote `https://github.com/Antony0610/Pet_Connect_Ai.git`.
Tags: **`v1.0.0`**, **`v1.0.1`**. HEAD `15cd917` = `v1.0.1-19-g15cd917`.

**Milestones (newest → oldest):**

| Commit | Milestone |
|---|---|
| `15cd917` | Wire AI Hub + Smart Collar routes (module complete) |
| `00e3236` | Smart Collar screens |
| `ea2591e` | AI Hub screens |
| `06ff896` | AI / Collar widget primitives |
| `4df4ff0` | Notifications / Profile / Settings screens |
| `e5d3f47` | Fix Health Passport compile |
| `3dd09e9` | Wire Health Passport routes |
| `e615d43` | Health Passport module |
| `2eee86d` | Fix pet_owner analyzer issues |
| `722951a` | Activate Lost Mode screen |
| `3ed564c` | My Pets List screen |
| `9029ac3` | OwnerActionFab |
| `6947386` | Home Dashboard screen |
| `a8c9df2` | Shared portal shell (OwnerScaffold / app bar / nav) |
| `603c99f` | Owner notifications / search routes |
| `0b4909b` | GlassCard |
| `382dcfe` | Extend design tokens |
| `0e22303` | Fix OTP → final 6-digit |
| `5933594` | Authentication end-to-end |
| `c79ffb3` | Stabilize Foundation `v1.0.1` + scaffold auth |
| `1042d9f` | `dart format` pass |
| `35710c4` | Remove flutter_hooks |
| `cd0164e` | Sync folder structure |
| `ff79ff2` | Foundation QA pass |

**Version history:** Foundation stabilized at `v1.0.0` → `v1.0.1`; all
subsequent Auth + Pet Owner work sits on `master` above `v1.0.1`.

---

## 13. Current Completion Status (estimates)

| Area | % | Notes |
|---|---:|---|
| **Foundation** | ~100% | Theme, tokens, widgets, routing, DI, CI, docs all shipped. |
| **Authentication** | ~100% | UI + Supabase + 6-digit OTP done; `/forgot-password` still placeholder. |
| **Pet Owner** | ~85–90% | Core + Health + AI Hub + Smart Collar done; **Community pending**; Search placeholder. |
| **Veterinarian** | ~0% | Routes only; all screens placeholder. |
| **Volunteer / Rescue** | ~0% | Routes only; all screens placeholder. |
| **Administrator** | ~0% | Routes only; all screens placeholder. |
| **Overall application** | ~40–45% | One of four portals substantially built; backend bindings for AI/Collar still pending. |

---

## 14. Next Recommended Development Order

1. **Community** (Pet Owner) — the only remaining Pet Owner sub-feature; replace
   the `/owner/community` placeholder.
2. **Veterinarian portal** — `/vet` home, appointments, patients (+ detail),
   profile.
3. **Volunteer / Rescue portal** — `/rescue` home, cases (+ detail), map,
   profile.
4. **Administrator portal** — `/admin` home, users, moderation, analytics.
5. **Integration** — bind AI Hub to the live AI service (Gemini + RAG) and Smart
   Collar to Maps + collar telemetry; wire `RouteGuard` session/role gating;
   persist `ThemeMode`; complete Forgot Password.
6. **QA** — expand test coverage, enable localization, accessibility + responsive
   passes.
7. **Release** — versioning/tagging, store/deployment prep per
   `docs/DEPLOYMENT_PLAN.md`.

---

## 15. Future Claude Instructions

**What is already complete — do not rebuild:**
- The **theme + token system** (`lib/core/theme/`) and the **shared component
  library** (`lib/shared/widgets/`). Consume them; do not re-author them.
- The **routing graph** (`lib/router/`) — paths and names are stable contracts.
  Add routes; don't renumber or rename existing ones.
- **Authentication** (screens, domain, data, providers, 6-digit OTP). It works
  end-to-end — extend (e.g. Forgot Password), don't rewrite.
- Pet Owner **Core, Health Passport, AI Hub, Smart Collar** screens and their
  `health_widgets` / `ai_widgets` / `collar_widgets` primitive libraries.

**What should never be rebuilt or redesigned:**
- The frozen Stitch Light design and its Dark counterpart (§2). No restyling, no
  workflow simplification, no screen merging, no hardcoded style values.

**Files to trust as source of truth:**
- This `PROJECT_CONTEXT.md`; `FOUNDATION_COMPLETE.md`; `docs/*`;
  `lib/router/route_paths.dart` (route contracts); `lib/core/theme/*` (design);
  `pubspec.yaml` (deps); `.github/workflows/ci.yml` (quality gates).

**How to proceed on new work:**
1. Read the frozen Stitch Light design for the target screen **before** coding.
2. Reuse existing tokens + shared/feature widgets; add a new feature-scoped
   primitive library only if the sub-feature needs one (mirror
   `ai_widgets`/`collar_widgets`).
3. Follow Clean Architecture layering; add Riverpod providers for DI/state;
   return `Either<Failure, T>`.
4. Build one widget tree that serves both themes (token-driven, responsive via
   `_horizontalMargin` + `maxContentWidth`).
5. Add routes by declaring paths/names in `route_paths.dart` and wiring builders
   in `app_router.dart`; navigate with `context.goNamed`.
6. After the feature is complete: `flutter analyze` + `flutter test`; fix only
   what your feature introduced (ignore the repo-wide info-level import lints).
7. Commit logical milestones; push after the feature; **then stop for review**
   before starting the next module.

**Environment notes:** bash `PATH` is broken — use the absolute git binary
(`/c/Program Files/Git/cmd/git.exe`) and `git -C <repo>` (parallel bash calls do
not share `cd`). Repo lives in `petconnect_ai/`, branch `master`. `.env` and
`.mcp.json` are secrets and untracked; the Stitch key in `.mcp.json` is pending
rotation — never print it.
