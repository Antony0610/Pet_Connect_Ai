# PetConnect AI — PROJECT_CONTEXT.md

> **Single source of truth for AI agents and developers.**
> This document describes the repository as it exists today so that any future
> session can continue development **without the previous chat history**. It is
> descriptive documentation reflecting the production state of the codebase.
>
> _Reflects `master` branch with all 4 native portals, React 19 web portal, and Supabase Edge Functions._

---

## 1. Project Overview

| Field | Value |
|---|---|
| **Project name** | PetConnect AI (`petconnect_ai`) |
| **Purpose** | A production-grade multi-portal pet-care and emergency ecosystem: Pet Owners manage health passports, AI triage, and GPS smart collar telemetry; Veterinarians manage patient triage, SOAP notes, and digital prescriptions; Volunteer/Rescue teams manage rescue operations and stray sighting reports; Administrators manage staff, security, and platform health; and a public React 19 web portal enables zero-app emergency recovery. |
| **Overall architecture** | Clean Architecture (data / domain / presentation) with feature-first organization, Riverpod DI + state, GoRouter navigation, Supabase backend, and React 19 SPA web portal. |
| **Flutter / Dart** | Dart SDK `>=3.12.0 <4.0.0` (Flutter 3.44.9 / Dart 3.12.2). |
| **Web Portal Stack** | React 19, TypeScript, Vite, CSS Design Tokens (`tokens.css`), Supabase JS SDK. |
| **Main packages** | `flutter_riverpod` ^2.6.1, `go_router` ^14.6.2, `supabase_flutter` ^2.9.0, `dio` ^5.7.0, `freezed`/`json_serializable`, `google_fonts` ^6.2.1, `dartz` ^0.10.1, `flutter_map` ^7.0.2, `firebase_messaging`/`firebase_core`, `flutter_secure_storage`, `flutter_dotenv`. |
| **Repository URL** | https://github.com/Antony0610/Pet_Connect_Ai.git |
| **Current branch** | `master` |
| **Declared release** | `v1.0.3` |

**Portal status at a glance:**
- **Pet Owner Portal**: 100% complete (52 screens — Digital Health Passport, AI Hub, Smart Collar, Document Vault, Community).
- **Veterinarian Portal**: 100% complete (14 screens — Patient queue, SOAP consultations, digital prescription PDF generator, pharmacy inventory).
- **Volunteer & Rescue Portal**: 100% complete (15 screens — EOC dashboard, stray animal reports, active rescue operations, volunteer network).
- **Administrator Portal**: 100% complete (9 screens — User management, moderation, security center, platform health audits).
- **Authentication**: 100% complete (8 screens — Login, registration, 6-digit OTP, role-based routing).
- **Web Portal**: 100% complete (React 19 SPA with `/emergency/:id`, `/verify/:id`, `/adopt`, `/missing`, and `TAG-PROTOTYPE-001` QR simulator).

---

## 2. Design Authority

The visual design is frozen and authoritative:
- **Stitch Light Theme is the design authority** for colors, typography, spacing, radius, and elevations.
- **Dark Theme is derived from Light** using role-mapped counter tokens (`AppTheme`).
- **AI Content Rule**: All AI-generated content is encapsulated inside `AiGradientBorderCard` with `AiSourceChip` attribution and `AiConfidenceBadge`.
- **Editorial Web Aesthetic**: The web portal uses a warm-monochrome, minimalist editorial palette (`web_portal/src/styles/tokens.css`) devoid of artificial gradients.

---

## 3. Architecture & Codebase Layout

**Clean Architecture, feature-first.**

```
petconnect_ai/
├── android/                   # Native Android wrapper (AGP 8.9.1, Kotlin 2.2.20)
├── docs/                      # Authoritative technical documentation
├── lib/
│   ├── main.dart              # Entry → bootstrap()
│   ├── bootstrap.dart         # .env → Supabase.init → ProviderScope
│   ├── app.dart               # MaterialApp.router (theme + router)
│   ├── core/                  # Infrastructure (config, error, network, theme, providers)
│   ├── features/              # Feature modules (auth, pet_owner, veterinarian, volunteer_rescue, administrator, ai_services, smart_collar)
│   ├── router/                # route_paths, route_guard, app_router
│   └── shared/                # Shared widgets, models, entities
├── release/                   # Release config & git-ignore rules for binary packages
├── supabase/
│   ├── functions/             # Serverless Edge Functions (ai-assistant, ai-symptom-scan, ai-report-generator)
│   └── migrations/            # SQL migrations & RLS policies
└── web_portal/                # Standalone React 19 + TypeScript + Vite SPA
```

---

## 4. Serverless AI Suite & Model Cascade

AI inference is isolated server-side inside Supabase Edge Functions:
1. **`gemini-3.7-flash`**: Flagship veterinary multimodal reasoning engine.
2. **`gemini-3.1-flash-lite`**: Sub-second low-latency instant fallback.
3. **`gemini-3.8-flash`**: High-throughput reasoning.
4. **`gemini-3.6-flash`**: Rapid conversational triage.

### Edge Functions
- **`ai-assistant`**: General & veterinary consultation, RAG pet profile injection, conversation history bounding (-15 turns), Malayalam (`ml_IN`) & English support, prompt injection defense.
- **`ai-symptom-scan`**: Dermatological computer vision, base64 image parsing (~8MB limit), SSRF URL validation (`isSafeUrl`), structured JSON triage (`analysis_summary`, `urgency_level`: `ROUTINE`/`URGENT`/`EMERGENCY`, `recommendations`).
- **`ai-report-generator`**: Automated health score (0-100), key preventative milestones, dietary guidelines.

---

## 5. IoT Smart Collar & Prototype Simulation

- **Framing**: ESP32 smart collar hardware is specified as an active **R&D prototype**.
- **Prototype Tag Simulator**: Demonstrations and testing leverage the single authoritative tag **`TAG-PROTOTYPE-001`**.
- **Interactive QR Simulator Modal**: `web_portal/src/components/QrSimulatorModal.tsx` simulates scanning the collar tag and navigates instantly to live emergency profiles.
- **OpenStreetMap Integration**: Uses `flutter_map` with OpenStreetMap tile layers and Nominatim reverse geocoding.

---

## 6. Current Completion Matrix

| Area | Status | Reconciled Details |
|---|:---:|---|
| **Foundation & Themes** | 100% | Design tokens, M3 light/dark themes, shared widgets, Riverpod DI. |
| **Authentication & Onboarding** | 100% | 8 screens, Supabase Auth, 6-digit OTP, role-based GoRouter guards. |
| **Pet Owner Portal** | 100% | 52 screens, Health Passport, AI Hub, Smart Collar OSM HUD, Document Vault. |
| **Veterinarian Portal** | 100% | 14 screens, triage queue, SOAP notes, digital prescription PDFs, pharmacy. |
| **Volunteer & Rescue Portal** | 100% | 15 screens, active rescue operations, EOC dispatch, stray reports. |
| **Administrator Portal** | 100% | 9 screens, staff roster, security audit logs, platform health diagnostics. |
| **Web Portal (SPA)** | 100% | React 19 + Vite, `/emergency`, `/verify`, `/adopt`, `/missing`, QR simulator modal. |
| **Edge Functions & AI Engine** | 100% | Gemini 3.x cascade, circuit breaker, SSRF protection, CORS whitelisting. |
| **Android Release Build** | 100% | Verified release APK/AAB build pipeline, AGP 8.9.1, Java 17 desugaring. |
