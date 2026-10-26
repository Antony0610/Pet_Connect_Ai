# 🐾 PetConnect AI — Next-Gen Intelligent Pet Care Ecosystem

[![Release](https://img.shields.io/badge/Release-v1.0.3-2ea44f?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Antony0610/Pet_Connect_Ai/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![React](https://img.shields.io/badge/Web%20Portal-React%2019%20%2B%20Vite-61DAFB?logo=react)](web_portal)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%2B%20Auth%20%2B%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-3.7%20Flash%20%26%203.8%20Flash-8E75B2?logo=google)](https://deepmind.google/technologies/gemini/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20Riverpod-orange)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**PetConnect AI** is a production-grade, AI-driven pet care, health management, and emergency safety ecosystem. It unites companion digital health passports, IoT smart collar telemetry and prototype simulation, multimodal veterinary AI triage, clinical EMR workflows, volunteer rescue operations, and a public emergency web portal across 4 dedicated mobile portals and a modern web suite.

---

## 📱 Android Mobile Application & Distribution

PetConnect AI provides a native, production-grade Android application built with Flutter:

| Component | Specification / Link | Notes |
| :--- | :--- | :--- |
| 🏷️ **Current Release Version** | [**Release v1.0.3**](https://github.com/Antony0610/Pet_Connect_Ai/releases) | Official Production Release Tag |
| 📦 **Android App Package** | `com.petconnect.ai.petconnect_ai` | Target SDK 34 (Android 14), Min SDK 21 |
| 🛠️ **Build Artifacts** | `flutter build apk --release` | Compiled locally or attached to GitHub Releases |

> [!NOTE]
> In accordance with security best practices, raw compiled binary packages (`.apk`, `.aab`) are excluded from Git repository tracking to prevent key leaks and repository bloat. Users and testers can download official compiled releases directly from the [**GitHub Releases**](https://github.com/Antony0610/Pet_Connect_Ai/releases) tab or compile the APK locally in one command.

### Building the Release APK Locally:
```bash
cd petconnect_ai
flutter pub get
flutter build apk --release
```
The compiled APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🚀 Key Platform Features

### 1. 🤖 Multimodal AI Health Assistant & Visual Scribe
- **Advanced Gemini 3.x Cascade**: Low-latency veterinary intelligence backed by Google Gemini:
  - ⚡ `gemini-3.7-flash` (Flagship multimodal engine with deep clinical reasoning)
  - 🚀 `gemini-3.8-flash` (Next-gen ultra-high throughput reasoning model)
  - ⚡ `gemini-3.1-flash-lite` (Sub-second instant response fallback)
  - ✨ `gemini-3.6-flash` (Rapid triage conversational engine)
- **Computer Vision Symptom Inspection**: Real-time camera or gallery uploads evaluating dermatological symptoms, facial fold hygiene, coat condition, and nutrition labels.
- **Bilingual Voice Scribe `[EN | ML]`**: Interactive voice input supporting speech recognition in both **Malayalam (`ml_IN`)** and **Indian English (`en_IN`)**.
- **Executable In-App Action Protocol**: AI generates actionable UI buttons to book vet appointments, activate collar lost mode, calculate toxicity dosage, ring collar buzzers, and set medication reminders.

### 2. 🦾 Animated 3D Mascot Companions & Emotional Visors
- **4 Selectable Character Avatars**:
  - 🤖 **Classic Aero Bot** — Aerodynamic companion with glowing neon accents
  - 🐱 **Cyber Neko** — Playful robotic feline with reactive ear motions
  - 🐶 **Cyber Pup** — Loyal canine companion with alert poses
  - 🌌 **Astral Bot** — Holographic cosmic guardian
- **Dynamic Emote Visor**: Real-time expressions (`^ ‿ ^`, `★ ‿ ★`, `♥ ‿ ♥`, `• ‿ •`, `o ‿ o`) responding dynamically to diagnostic urgency and conversation sentiment.

### 3. 🛰️ IoT Smart Collar Telemetry & Prototype Simulator
- **Live OpenStreetMap Tracking**: Real-time GPS location tracking with automatic geocoding to the user's city via OpenStreetMap's Nominatim service.
- **Safe Zone Geofencing**: Configurable safe zone perimeter (50m to 1,000m) with tap-to-relocate map controls and instant exit alerts.
- **Active Telemetry HUD**: Monitors battery level, BLE 5.3 signal strength, LTE-M connectivity, and normothermic body temperature (38.6°C).
- **R&D Prototype Tag Simulator (`TAG-PROTOTYPE-001`)**: Authoritative prototype tag simulation across both mobile and web surfaces with instant QR code scanning and verification.
- **Emergency Lost Pet Radar**: One-tap trigger broadcast that pings nearby community members, volunteers, and rescue shelters with last-known GPS coordinates.

### 4. 🏥 Clinical EMR Workspace & Digital Prescriptions
- **Complete Medical History**: Chronic conditions, allergy registers, surgeries, and vaccination histories synced live with Supabase PostgreSQL.
- **SOAP Clinical Notes**: Attending veterinarians record Subjective, Objective, Assessment, and Plan notes with AI assistance.
- **Automated Digital Prescription PDFs**:
  - Itemized pharmacy lines and dosage instructions.
  - Official clinic certification with veterinary council registration numbers.
  - Generates verifiable PDF documents archived directly into the pet's **Document Vault**.
- **Document Vault**: Preview, print, export, share, or delete veterinary certificates, lab reports, and invoices.

### 5. 📅 Direct Appointment Booking & Practitioner Queue
- **Owner-to-Clinic Booking Sheet**: Browse verified clinics and veterinarians, select preferred time slots, specify triage urgency, and book consultations in one tap.
- **Real-Time Practitioner Triage Queue**: Live clinic queue synced via Supabase Realtime for instant patient admission and status updates.

### 6. 🌐 Zero-App Emergency Web Portal (React 19 + Vite)
Located in `web_portal/`, the web suite enables Good Samaritans to inspect pet credentials and report sightings without installing the mobile app:
- `/emergency/:id` — First Responder emergency dossier with critical medical alerts and one-tap owner calling.
- `/missing/:id` — Live lost pet radar with instant sighting submission and WhatsApp dispatch.
- `/adopt/:id` — Community adoption showcase with verified behavioral indicators.
- `/verify/:id` — Digital vaccination and rabies certificate verification.
- `TAG-PROTOTYPE-001` Simulator — Embedded modal demonstrating instant emergency resolution.

### 7. 💬 Community Hub & Realtime Messaging
- **1-on-1 & Group Chats**: Real-time communication channels (`Adoption`, `Rescue`, `Breed Club`, `General Care`).
- **Profile Preview Modals**: Tap any community member's avatar to inspect verified badges, bio, and contact information.

---

## 🏛️ Multi-Portal Architecture

PetConnect AI is organized into 4 purpose-built mobile portals and 1 public web portal:

```
┌─────────────────────────────────────────────────────────────┐
│                       PetConnect AI                         │
├──────────────┬──────────────┬───────────────┬───────────────┤
│  Pet Owner   │ Veterinarian │ Volunteer &   │ Administrator │
│    Portal    │    Portal    │ Rescue Portal │    Portal     │
│   (/owner)   │    (/vet)    │  (/volunteer) │   (/admin)    │
├──────────────┴──────────────┴───────────────┴───────────────┤
│                   Public Web Portal (SPA)                   │
│         /emergency  ·  /verify  ·  /adopt  ·  /missing      │
└─────────────────────────────────────────────────────────────┘
```

1. **Pet Owner Portal (`/owner`)**: Digital Health Passport, vaccination schedule, consultation booking, AI symptom scanner, Document Vault, community feeds, and smart collar GPS tracker.
2. **Veterinarian Portal (`/vet`)**: Patient triage queue, live telemetry vitals HUD, SOAP consultation notes, digital prescription generator, and pharmacy inventory.
3. **Volunteer & Rescue Portal (`/volunteer`)**: Emergency dispatch operations, live stray animal reports, lost pet sighting verification, and rescue achievement milestones.
4. **Administrator Portal (`/admin`)**: Staff credentials roster, security event center, user moderation, system health audits, and Indian Standard Time (`hh:mm:ss a IST`) activity logs.

---

## 🏗️ Technical Architecture & Project Structure

```
Pet_Connect_Ai/
├── petconnect_ai/
│   ├── android/              # Native Android runner (AGP 8.9.1, Kotlin 2.2.20)
│   ├── assets/               # Canonical branding, icons, and illustrations
│   ├── docs/                 # Authoritative architecture and operations specs
│   ├── lib/
│   │   ├── core/             # Design tokens, theme system, network clients, external actions
│   │   ├── features/         # Feature-first Clean Architecture (4 portals, AI, IoT)
│   │   ├── router/           # GoRouter routing & role-based authentication guards
│   │   └── shared/           # Reusable UI components, cards, buttons, loaders
│   ├── release/              # Release configuration notes and package ignores
│   ├── supabase/
│   │   ├── functions/        # Deno Edge Functions (ai-assistant, ai-symptom-scan, ai-report-generator)
│   │   └── migrations/       # PostgreSQL migrations and RLS policies
│   ├── web_portal/           # React 19 + TypeScript + Vite Single Page Application
│   └── pubspec.yaml          # Flutter dependencies
```

- **Mobile Framework**: [Flutter 3.44.9](https://flutter.dev) (Dart 3.12.2)
- **Web Framework**: [React 19](https://react.dev) with [Vite](https://vite.dev) and TypeScript
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security, Realtime, Storage)
- **AI Engine**: Google Gemini 3.7 Flash & 3.8 Flash via secure Supabase Edge Functions
- **Mapping**: OpenStreetMap & Flutter Map with Nominatim Reverse Geocoding

---

## 🔒 Security & Environment Architecture

PetConnect AI enforces strict credential isolation:
- **Zero Secrets in Git**: Private API keys and server tokens are kept out of source code.
- **Client Access**: The Flutter app reads configurations at runtime from `.env` (strictly git-ignored).
- **Server-Side AI**: Gemini API keys for backend routines live in **Supabase Edge Function secrets** (`supabase secrets set GEMINI_API_KEY=...`).
- **Defensive Edge Hardening**: Server-side SSRF validation on remote URLs, origin CORS whitelisting, and prompt injection defense.
- **Row-Level Security (RLS)**: Enforced across all Supabase PostgreSQL tables to guarantee pet records, medical data, and user messages are private to authorized accounts.

---

## 🛠️ Getting Started & Local Development

### 1. Mobile Application (Flutter)

```bash
# Clone the repository
git clone https://github.com/Antony0610/Pet_Connect_Ai.git
cd Pet_Connect_Ai/petconnect_ai

# Install dependencies
flutter pub get

# Configure environment variables (.env)
cp .env.example .env
# Edit .env with your Supabase URL and Anon Key

# Run static analysis
flutter analyze

# Launch on connected Android device or emulator
flutter run
```

### 2. Web Portal (React 19 + Vite)

```bash
cd petconnect_ai/web_portal

# Install dependencies
npm install

# Start local development server
npm run dev
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
