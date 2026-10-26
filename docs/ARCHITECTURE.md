# System Architecture

PetConnect AI is a production-grade, AI-powered pet care and emergency safety ecosystem. It unites four native mobile application portals (**Pet Owner**, **Veterinarian**, **Volunteer & Rescue**, and **Administrator**), a public **React 19 Web Portal**, a serverless **Supabase Edge & PostgreSQL** backend, and an **IoT Smart Collar** telemetry and simulation pipeline.

This document describes the end-to-end multi-platform architecture that keeps this ecosystem secure, performant, and maintainable.

---

## 1. High-Level Ecosystem Topology

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             CLIENT SURFACES                                      │
├─────────────────────────────────────────────────┬────────────────────────────────┤
│          Native Flutter Mobile App              │     Modern Web Portal (SPA)    │
│  - Pet Owner Portal (/owner)                    │  - React 19 + Vite + TS        │
│  - Veterinarian Clinical Portal (/vet)          │  - Minimalist Editorial Design │
│  - Volunteer & Rescue Dispatch (/volunteer)     │  - Public Medical Dossier      │
│  - System Administrator Suite (/admin)          │  - Lost Pet Radar / Sightings  │
│  - OpenStreetMap & Collar HUD                   │  - Adoption Inquiries          │
│  - Animated Companion Avatars & Voice Scribe    │  - Interactive Tag Simulator   │
└────────────────────────┬────────────────────────┴────────────────┬───────────────┘
                         │                                         │
                         │ REST / Realtime / Storage               │ Supabase JS SDK
                         ▼                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        SUPABASE CLOUD INFRASTRUCTURE                             │
├──────────────────────────────────────────────────────────────────────────────────┤
│  ⚡ EDGE FUNCTIONS (Deno Serverless)                                             │
│     ├── ai-assistant (Universal clinical & open-domain veterinary intelligence)  │
│     ├── ai-symptom-scan (Multimodal dermatological & symptom computer vision)    │
│     └── ai-report-generator (Deterministic health score & clinical milestones)   │
│                                                                                  │
│  🔒 AUTHENTICATION & ROW-LEVEL SECURITY (RLS)                                    │
│     ├── Multi-role RBAC: owner, vet, volunteer, admin                            │
│     └── PostgreSQL RLS policies isolating records per user and clinic            │
│                                                                                  │
│  🗄️ POSTGRESQL DATABASE & EXTENSIONS                                            │
│     ├── Relational EMR: pets, health_records, vaccinations, prescriptions        │
│     ├── pgvector: Embeddings for RAG search & knowledge base                     │
│     └── Realtime Engine: Live collar telemetry, clinic queues, SOS broadcasts    │
│                                                                                  │
│  📦 STORAGE BUCKETS                                                              │
│     ├── pet-media (Public pet profiles, photos, and gallery)                     │
│     └── pet-documents (Encrypted private medical certificates & lab PDFs)        │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   EXTERNAL AI & IOT PROTOCOL INTEGRATIONS                        │
├────────────────────────────────────────────────┬─────────────────────────────────┤
│           Google Gemini AI Engine              │  IoT Smart Collar (Phase 2 Spec)│
│  - gemini-3.1-flash-lite (Ultra-Low Latency)   │  - Seeed Studio XIAO ESP32-C6   │
│  - gemini-3.8-flash (High-Throughput Reasoning)│  - ADIY EC200U GNSS & LTE Cat 1 │
│  - gemini-2.5-flash / gemini-2.0-flash Fallback│  - LIS2DU12 3-Axis Accelerometer│
│  - Resilient Model Cascade & Circuit Breaker   │  - MAX17048 I²C Fuel Gauge      │
│  - Clinical Prompt Hardening & SSRF Defense    │  - Active-LOW SOS & NPN Buzzer  │
│  - Sub-second Triage & Symptom Evaluation      │  - TAG-PROTOTYPE-001 Simulator  │
└────────────────────────────────────────────────┴─────────────────────────────────┘
```

---

## 2. Multi-Portal Domain Model

The ecosystem supports 4 authenticated native roles and 1 unauthenticated public surface:

| Persona / Portal | Route Namespace | Primary Capabilities |
| :--- | :--- | :--- |
| **Pet Owner** | `/owner/*` | Digital Health Passport, vaccination alerts, appointment booking, AI assistant, Document Vault, OpenStreetMap GPS collar tracking, emergency lost mode. |
| **Veterinarian** | `/vet/*` | Realtime triage queue, patient medical records, SOAP clinical consultation notes, verifiable digital prescription PDFs, clinic pharmacy inventory. |
| **Volunteer & Rescue** | `/volunteer/*` | Emergency Operations Center (EOC), stray animal rescue requests, lost pet sighting verification, mission dispatching, community badges. |
| **Administrator** | `/admin/*` | Staff management, security audit logs, community moderation, platform analytics, system health monitoring with Indian Standard Time (`hh:mm:ss a IST`). |
| **Public Web Portal** | `/*` (`/emergency`, `/verify`, `/adopt`, `/missing`) | Zero-app emergency collar QR scanner, finder contact form, microchip verification, lost pet radar, adoption listings. |

---

## 3. Flutter Mobile Client Architecture

The Flutter codebase follows **Clean Architecture** organized **feature-first**:

```
presentation  ──►  domain  ◄──  data
                   (pure Dart)
```

### 3.1 Layers

1. **Presentation Layer (`features/<feature>/presentation`)**:
   - **Screens**: Composed top-level routes registered in GoRouter.
   - **Widgets**: Reusable, component-tokenized UI elements.
   - **Controllers**: Riverpod `AsyncNotifier` / `Notifier` holding reactive UI state.
2. **Domain Layer (`features/<feature>/domain`)**:
   - Pure Dart entities (built with `freezed` or plain immutable classes).
   - Abstract repository contracts (`PetRepository`, `AuthRepository`).
   - Single-responsibility UseCases returning `Either<Failure, T>`.
3. **Data Layer (`features/<feature>/data`)**:
   - Models extending domain entities with `fromJson` / `toJson` serialization.
   - Remote datasources interacting with `SupabaseClient` and Dio.
   - Repository implementations catching typed `Exception`s and returning sealed `Failure`s.

### 3.2 State Management & Dependency Injection
- **Riverpod 2.x**: Serves as both reactive state container and dependency injection mechanism.
- Core clients (`supabaseClientProvider`, `dioProvider`, `loggerProvider`) reside in `core/providers/core_providers.dart`.
- Eliminates manual service locators (`get_it`); all dependencies are mockable via `ProviderScope(overrides: [...])` in unit and widget tests.

### 3.3 Error Handling Flow
Errors are values, not unexpected runtime exceptions:
```
Datasource (throws ServerException)
   ↓
Repository (catches and returns Left(ServerFailure))
   ↓
UseCase (propagates Either<Failure, T>)
   ↓
Controller (.fold(onLeft: (f) => AsyncError, onRight: (s) => AsyncData(s)))
   ↓
UI (renders ErrorView or Snackbar)
```

---

## 4. Modern Web Portal Architecture

Located in `web_portal/`, the web companion provides instant web access for emergency pet recovery without requiring app installation:

### 4.1 Tech Stack
- **Framework**: React 19 with Vite and TypeScript.
- **Styling**: Vanilla CSS Design Tokens (`src/styles/tokens.css`) using an editorial, warm-monochrome aesthetic (no generic AI gradients).
- **Backend SDK**: `@supabase/supabase-js` communicating directly with Supabase PostgreSQL and Storage.
- **Routing**: Client-side hash/path navigation supporting `/emergency/:id`, `/verify/:id`, `/adopt/:id`, `/missing/:id`.
- **Hosting & SPA Rewrites**: Configured via `vercel.json` with universal wildcard rewrites to `index.html`.

### 4.2 Interactive QR Simulation (`QrSimulatorModal.tsx`)
Enables testers and good Samaritans to experience the emergency workflow with a single authoritative R&D tag:
- Tag ID: `TAG-PROTOTYPE-001`.
- Simulates scanning a smart collar or collar medal, navigating instantly to the corresponding live emergency profile.

---

## 5. Serverless AI Tier & Resilience

The AI tier connects Flutter and Web clients to Google Gemini 3.x models via Supabase Edge Functions:

### 5.1 Model Cascade
1. **Primary**: `gemini-3.7-flash` (Deep clinical veterinary reasoning & computer vision).
2. **Fallback 1**: `gemini-3.1-flash-lite` (Sub-second low-latency inference).
3. **Fallback 2**: `gemini-3.8-flash` (High-throughput reasoning).
4. **Fallback 3**: `gemini-3.6-flash` (Rapid triage backup).

### 5.2 Client Circuit Breaker
- Direct persistent `HttpClient` with connection pooling (4s connection timeout, 5m idle timeout).
- In-memory failure blacklist (`_circuitBreakerBlacklist`) with automatic 5-minute cooldown.

### 5.3 Edge Security Defenses
- **SSRF Protection**: Image URLs inspected with `isSafeUrl`, blocking loopback (`127.0.0.1`), local network ranges (`10.*`, `192.168.*`, `172.16.*`), and cloud metadata services (`169.254.*`).
- **CORS Whitelist**: Restricts browser requests to localhost, `127.0.0.1`, `*.vercel.app`, and `*petconnect*`.
- **Prompt Injection Hardening**: User text framed strictly as clinical observation data; prompt bounds enforced (4,000 chars for chat, 3,000 for symptoms); null bytes stripped.

---

## 6. IoT Smart Collar & Telemetry Architecture

- **Phase Separation**:
  - **Phase 1 (Software Platform)**: Production mobile OpenStreetMap tracking, radial geofencing (50m–1,000m), real-time Supabase telemetry ingestion, and the authoritative `TAG-PROTOTYPE-001` test simulator.
  - **Phase 2 (Physical Hardware Integration)**: Physical collar prototype implementation targeting the frozen specification below.
- **Frozen Hardware Specification**:
  - **Main Controller**: Seeed Studio XIAO ESP32-C6 (compact RISC-V controller).
  - **GNSS & Cellular**: ADIY EC200U development board (Quectel EC200U LTE Cat 1 + GNSS all-in-one).
  - **Motion Sensing**: LIS2DU12 3-axis accelerometer over shared I²C bus. *(Reconciled against older LIS3DH notes).*
  - **Battery Monitoring**: MAX17048 fuel gauge IC via dedicated `BAT/CELL` connection to Li-Po positive terminal.
  - **Battery & Protection**: 1S 3.7V nominal Li-Po with 5A class protection PCB. *(Capacity pending BOM confirmation: 700 mAh vs 1000 mAh; protection is NOT charging).*
  - **Emergency Input**: Momentary active-LOW SOS button on D2 / GPIO2 with internal pull-up.
  - **Audible Alert**: Piezo buzzer driven by NPN transistor (2N2222) on D3 / GPIO21 with ~1kΩ base resistor.
  - **Modem Power Control**: SPST slide switch on EC200U high-current power path.
- **Explicit Exclusions**: No heart-rate, no SpO₂, no body temperature sensor, no camera/mic, no RGB LED, and no medical diagnostic claims.
- **Full Specification**: Detailed in [docs/HARDWARE_SPECIFICATION.md](file:///d:/Downloads/Pet_Connect_Ai/petconnect_ai/docs/HARDWARE_SPECIFICATION.md).

---

## 7. Security Architecture

1. **Zero Client Secrets**: Private API keys (`GEMINI_API_KEY`, Supabase Service Role) are never embedded in mobile client bundles or web code.
2. **PostgreSQL Row-Level Security (RLS)**: Enforced across all tables; records are accessible only by authorized owners or verified clinical staff.
3. **Encrypted Medical Vault**: Private medical records and lab reports are stored in the private `pet-documents` storage bucket with signed time-limited access URLs.
4. **Role Guards**: GoRouter guards intercept unauthenticated navigation and route users to their designated portal based on `profiles.role`.
