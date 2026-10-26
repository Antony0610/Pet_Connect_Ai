# Codebase Folder Structure

This document is the authoritative directory map of the PetConnect AI repository. It reproduces the full tree, explains the purpose of every top-level directory, feature module, web portal, and serverless component, and defines enforced naming conventions.

---

## 1. High-Level Project Tree

```
Pet_Connect_Ai/petconnect_ai/
├── android/                          # Native Android runner, AGP 8.9.1, Gradle 8.12.1, Kotlin 2.2.20
├── assets/                           # Canonical static assets (logos, icons, illustrations)
│   ├── icons/
│   ├── images/
│   └── illustrations/
├── docs/                             # Authoritative system documentation & architecture specs
├── lib/                              # Flutter application codebase (Clean Architecture)
│   ├── main.dart                     # Application entry point → calls bootstrap()
│   ├── bootstrap.dart                # Async init: dotenv, Supabase, logging, DI
│   ├── app.dart                      # Root MaterialApp.router + ProviderScope + M3 theme
│   ├── core/                         # Cross-cutting framework infrastructure
│   ├── features/                     # Feature-first domain modules (4 Portals + AI + IoT)
│   ├── router/                       # GoRouter route graph, guards, and observer
│   └── shared/                       # Cross-feature design system tokens, widgets, and base DTOs
├── release/                          # Release artifacts, version notes, and package ignore rules
├── supabase/                         # Backend migrations & serverless edge functions
│   ├── functions/                    # Deno serverless microservices
│   │   ├── ai-assistant/             # Universal clinical veterinary & open-domain assistant
│   │   ├── ai-symptom-scan/          # Multimodal computer vision symptom inspector
│   │   └── ai-report-generator/      # Automated health scoring and milestone generator
│   └── migrations/                   # PostgreSQL schema migrations and RLS policies
├── test/                             # Unit, widget, and integration test suites
│   ├── unit/                         # Pure Dart tests (UseCases, Repositories, Models)
│   ├── widget/                       # Component and screen tests
│   └── integration/                  # End-to-end integration flows
├── web/                              # Flutter web runner support
├── web_portal/                       # Public Zero-App Emergency & Recovery Web Portal
│   ├── index.html                    # Single-page application HTML entry
│   ├── package.json                  # Vite, React 19, TypeScript dependencies
│   ├── tsconfig.json                 # TypeScript strict configuration
│   ├── vercel.json                   # Vercel deployment & universal SPA rewrite rules
│   ├── vite.config.ts                # Vite bundler configuration
│   └── src/                          # Web portal source code
│       ├── App.tsx                   # Main app router & layout wrapper
│       ├── main.tsx                  # React 19 root bootstrap
│       ├── components/               # Navbar, Footer, QrSimulatorModal
│       ├── lib/                      # Supabase JS SDK client
│       ├── pages/                    # HomePage, EmergencyPage, MissingPetsPage, AdoptionPage, VerifyPage
│       ├── styles/                   # Editorial design tokens (tokens.css)
│       └── types/                    # TypeScript interfaces
├── windows/                          # Windows desktop platform runner
├── .env.example                      # Template for client and server environment secrets
├── analysis_options.yaml             # Strict Dart static analysis rules
└── pubspec.yaml                      # Flutter dependencies and asset registrations
```

---

## 2. Flutter Mobile Architecture (`lib/`)

The mobile client is partitioned into three horizontal top-level packages alongside feature domains:

### 2.1 `lib/core/` — Cross-Cutting Infrastructure
- **`config/`**: Environment variable parsing (`env.dart`), flavor settings (`flavor.dart`), and application configuration (`app_config.dart`).
- **`error/`**: Sealed `Failure` hierarchy (`failures.dart`), typed runtime `Exception`s (`exceptions.dart`), and repository error mappers (`failure_mapper.dart`).
- **`network/`**: Persistent HTTP clients, Dio interceptors, and network connectivity monitors (`network_info.dart`).
- **`providers/`**: Global Riverpod providers (`core_providers.dart`) exposing the Supabase client, Dio, logger, and theme modes.
- **`theme/`**: The complete design system.
  - `tokens/`: Primitive tokens (colors, typography, spacing, radius, elevation).
  - `component_tokens/`: Component-level token maps (buttons, cards, chips).
  - `app_theme.dart`: Material 3 theme builders for light and dark modes.
- **`usecase/`**: Base abstract `UseCase<Type, Params>` contract and `NoParams`.
- **`utils/`**: General utility helpers, date formatters, validators, and Dart extension methods.

### 2.2 `lib/shared/` — Reusable Building Blocks
- **`domain/`**: Base `Entity` contracts and paginated container interfaces.
- **`data/`**: Base `Model` contracts.
- **`widgets/`**: Token-driven component library:
  - `buttons/`: `AppButton` (Primary, Secondary, Outline, Danger).
  - `cards/`: `AppCard`, `AiGradientBorderCard`.
  - `inputs/`: `AppTextField`, search bars, dropdowns.
  - `chips/`: `AppChip`, status indicators, `AiSourceChip`.
  - `loading/`: `LoadingOverlay`, progress rings.
  - `states/`: `EmptyState`, `ErrorView`, `SkeletonLoader`.
  - `avatar/`: `UserAvatar`, pet photo badges.

### 2.3 `lib/router/` — Navigation & Role Guarding
- **`route_paths.dart`**: Authoritative constants for all route paths across all 4 portals.
- **`route_guard.dart`**: Route interceptor verifying authentication session and enforcing role-based access rules.
- **`route_observer.dart`**: Route transition logger.
- **`app_router.dart`**: Complete GoRouter configuration.

---

## 3. Feature Modules (`lib/features/`)

Every feature module strictly implements Clean Architecture layers:
`data` ──► `domain` ◄── `presentation`

| Feature Module | Scope & Responsibility |
| :--- | :--- |
| **`auth/`** | Supabase Auth, login, registration, password recovery, OTP verification, onboarding. |
| **`pet_owner/`** | Primary portal (52 screens): Digital Health Passport, vaccination schedule, AI Hub, community feeds, document vault, appointment booking. |
| **`veterinarian/`** | Clinical portal (14 screens): Live triage queue, patient medical records, SOAP clinical consultation workspace, digital prescription PDF generator, clinic pharmacy inventory. |
| **`volunteer_rescue/`** | Emergency dispatch portal (15 screens): Active rescue operations, stray reports, sighting verification, emergency operations center, volunteer network. |
| **`administrator/`** | Governance portal (9 screens): Staff credential management, audit logging, security center, user moderation, platform health analytics. |
| **`ai_services/`** | Client AI engine: Gemini 3.x cascade, persistent connection pooling, circuit breaker blacklist, multimodal camera upload, bilingual voice scribe (`[EN | ML]`). |
| **`smart_collar/`** | IoT telemetry: Live OpenStreetMap tracking, safe zone geofencing, BLE 5.3 provisioning, battery & temperature HUD, lost mode radar. |

---

## 4. Modern Web Portal (`web_portal/`)

The standalone React 19 single-page application located in `web_portal/`:

```
web_portal/
├── index.html                        # HTML5 document with OpenGraph tags
├── package.json                      # React 19, TypeScript, Vite
├── tsconfig.json                     # Strict TypeScript config
├── vercel.json                       # Vercel deployment with universal SPA rewrites
├── vite.config.ts                    # Vite build configuration
└── src/
    ├── App.tsx                       # Client-side router & navigation shell
    ├── main.tsx                      # React root rendering
    ├── components/
    │   ├── Navbar.tsx                # Responsive top navigation bar
    │   ├── Footer.tsx                # Platform footer with emergency links
    │   └── QrSimulatorModal.tsx      # R&D Single Prototype Tag Simulator (TAG-PROTOTYPE-001)
    ├── lib/
    │   └── supabase.ts               # Supabase JS SDK client initialized from env
    ├── pages/
    │   ├── HomePage.tsx              # Platform landing page & features
    │   ├── EmergencyPage.tsx         # Live emergency dossier for lost pets (/emergency/:id)
    │   ├── MissingPetsPage.tsx       # Community lost pet radar & sighting submission (/missing)
    │   ├── AdoptionPage.tsx          # Available adoption profiles & inquiries (/adopt)
    │   └── VerifyPage.tsx            # Digital vaccination & microchip verification (/verify/:id)
    ├── styles/
    │   └── tokens.css                # Warm-monochrome editorial design tokens (no AI gradients)
    └── types/
        └── index.ts                  # TypeScript models (Pet, EmergencyContact, etc.)
```

---

## 5. Supabase Serverless & Backend (`supabase/`)

```
supabase/
├── config.toml                       # Supabase local development configuration
├── functions/
│   ├── tsconfig.json                 # Deno TypeScript configuration
│   ├── ai-assistant/
│   │   └── index.ts                  # Universal veterinary AI assistant (Gemini 3.x cascade)
│   ├── ai-symptom-scan/
│   │   └── index.ts                  # Multimodal symptom inspection with SSRF guards
│   └── ai-report-generator/
│       └── index.ts                  # Clinical health report & preventative milestone generator
└── migrations/
    └── 20261009000000_secure_storage_and_emergency_rpc.sql # Storage policies & emergency RPCs
```
