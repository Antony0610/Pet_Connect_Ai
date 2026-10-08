# 🐾 PetConnect AI — Next-Gen Intelligent Pet Care Ecosystem

[![Download APK](https://img.shields.io/badge/Download%20APK-Release%20v1.0.2-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Antony0610/Pet_Connect_Ai/raw/master/release/app-release.apk)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%2B%20Auth%20%2B%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-3.7%20Flash%20%26%203.8%20Flash-8E75B2?logo=google)](https://deepmind.google/technologies/gemini/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20Riverpod-orange)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**PetConnect AI** is a production-grade, AI-driven pet care, health management, and emergency safety ecosystem. It brings together companion health passports, IoT smart collar telemetry, multimodal veterinary AI triage, full clinical EMR workflows, and community rescue operations across 4 interconnected portals and a public web suite.

---

## 📱 Where to Find & Download the Android App

The pre-compiled, ready-to-install Android Release APK is stored directly in this repository:

| Asset | Location / Direct Link | Size |
| :--- | :--- | :--- |
| 📦 **Production Release APK** | [**`release/app-release.apk`**](release/app-release.apk) | **84.2 MB** |
| ⚡ **Direct Download Link** | [**Click Here to Download `app-release.apk`**](https://github.com/Antony0610/Pet_Connect_Ai/raw/master/release/app-release.apk) | **Latest v1.0.2** |
| 🏷️ **GitHub Release Tag** | [**Releases / v1.0.2**](https://github.com/Antony0610/Pet_Connect_Ai/releases/tag/v1.0.2) | **Official Release** |

### How to Download from GitHub:
1. **Direct Link**: Click the [**Direct Download Link**](https://github.com/Antony0610/Pet_Connect_Ai/raw/master/release/app-release.apk) above to download immediately to your phone or PC.
2. **Via Repository Tree**: In the GitHub repository file list, open the [`release/`](release/) folder, tap on [`app-release.apk`](release/app-release.apk), and click the **Download** or **View Raw** button.
3. **Via Releases Tab**: Click on **Releases** on the right side of the GitHub page to download the APK asset attached to release tag `v1.0.2`.
4. **Installing on Android**:
   - Transfer or download the APK onto your Android phone.
   - Open the file and tap **Install**.
   - If prompted, enable *"Install from Unknown Sources"* for your browser or file manager.

---

## 🚀 Key Feature Highlights

### 1. 🤖 Multimodal AI Health Assistant & Visual Scribe
- **Advanced Gemini 3.x Engine**: Seamless low-latency inference powered by Google Gemini:
  - ⚡ `gemini-3.7-flash` (Flagship multimodal engine with deep veterinary reasoning)
  - 🚀 `gemini-3.8-flash` (Next-gen ultra-high throughput reasoning model)
  - ✨ `gemini-3.6-flash` (Rapid conversational triage engine)
  - 🌟 `gemini-3.5-flash` (High-precision visual diagnostics)
  - ⚡ `gemini-3.1-flash-lite` (Sub-second instant response fallback)
- **Computer Vision Symptom Inspection**: Real-time camera or photo gallery uploads assessing dermatological symptoms, facial fold hygiene, coat condition, and nutrition labels with structured clinical triage.
- **Bilingual Voice Scribe `[EN | ML]`**: Interactive voice input supporting speech recognition in both **Malayalam (`ml_IN`)** and **Indian English (`en_IN`)**.
- **Executable In-App Action Protocol**: AI generates actionable UI buttons to book vet appointments, activate collar lost mode, calculate toxicity dosage, ring collar buzzers, and set medication reminders.

### 2. 🦾 Animated 3D Mascot Companions & Emotional Visors
- **4 Selectable Character Avatars**:
  - 🤖 **Classic Aero Bot** — Sleek aerodynamic companion with glowing neon accents
  - 🐱 **Cyber Neko** — Playful feline robotic avatar with dynamic ear motions
  - 🐶 **Cyber Pup** — Loyal canine companion with responsive alert poses
  - 🌌 **Astral Bot** — Cosmic holographic guardian with deep gradient rings
- **Dynamic Emote Visor**: Real-time animated expressions (`^ ‿ ^`, `★ ‿ ★`, `♥ ‿ ♥`, `• ‿ •`, `o ‿ o`) responding to conversation context and AI synthesis.
- **Physics Engine**: Smooth spring entrance, buoyant idle floating, and tactile haptic feedback.

### 3. 🛰️ IoT Smart Collar Telemetry & Geofencing
- **Live OpenStreetMap Tracking**: Real-time GPS location tracking with automatic geocoding to the user's city.
- **Safe Zone Geofencing**: Configurable safe zone perimeter (50m to 1,000m) with tap-to-relocate map controls and instant exit alerts.
- **Active Telemetry HUD**: Monitors battery level, BLE 5.3 signal strength, LTE-M connectivity, and normothermic body temperature (38.6°C).
- **Emergency Lost Pet Radar**: One-tap trigger broadcast that pings nearby community members, volunteers, and rescue shelters with last-known GPS coordinates.
- **Remote Collar Buzzer & LED Strobe**: Sound an audible buzzer or activate collar LEDs remotely to locate pets in low-light environments.

### 4. 🏥 Clinical EMR Workspace & Digital Prescriptions
- **Complete Medical History**: Chronic conditions, allergy registers, surgeries, and vaccination histories synced live with Supabase PostgreSQL.
- **SOAP Clinical Notes**: Attending veterinarians can record Subjective, Objective, Assessment, and Plan notes with AI assistance.
- **Automated Digital Prescription PDFs**:
  - Itemized pharmacy lines and dosage instructions.
  - Official clinic certification with veterinary council registration numbers.
  - Generates verifiable PDF documents archived directly into the pet's **Document Vault**.
- **Document Vault**: Preview, print, export, share, or delete veterinary certificates, lab reports, and invoices.

### 5. 📅 Direct Appointment Booking & Practitioner Queue
- **Owner-to-Clinic Booking Sheet**: Browse verified clinics and veterinarians, select preferred time slots, specify triage urgency, and book consultations in one tap.
- **Real-Time Practitioner Triage Queue**: Live clinic queue synced via Supabase Realtime for instant patient admission and status updates.

### 6. 🌐 Instant Emergency QR & Web Portal Ecosystem
- **Scannable Medical QR Badges**: Each pet receives a unique scannable QR badge linked to their digital emergency card.
- **Zero-App Public Web Portal**: Good Samaritans who scan a lost pet's collar tag can access public emergency web pages without installing the mobile app:
  - `web_portal/emergency.html`: Displays owner emergency contact, allergies, and finder reporting form.
  - `web_portal/verify.html`: Microchip verification and rabies vaccination status.
  - `web_portal/adopt.html`: Community adoption board with real-time pet profiles.
  - `web_portal/missing.html`: Active lost pet radar with immediate sighting submission.

### 7. 💬 Community Hub & Realtime Messaging
- **1-on-1 & Group Chats**: Real-time communication channels (`Adoption`, `Rescue`, `Breed Club`, `General Care`).
- **Profile Preview Modals**: Tap any community member's avatar to inspect verified badges, bio, and contact information.
- **Cross-Portal Push Notifications**: Persistent notification center synchronized across all portals.

---

## 🏛️ Multi-Portal Architecture

PetConnect AI is organized into 4 purpose-built portals accessible based on user credentials and roles:

```
┌─────────────────────────────────────────────────────────────┐
│                       PetConnect AI                         │
├──────────────┬──────────────┬───────────────┬───────────────┤
│  Pet Owner   │ Veterinarian │ Volunteer &   │ Administrator │
│    Portal    │    Portal    │ Rescue Portal │    Portal     │
└──────────────┴──────────────┴───────────────┴───────────────┘
```

1. **Pet Owner Portal (`/owner`)**:
   - Digital Health Passport, vaccination schedule, consultation booking, AI symptom scanner, Document Vault, community feeds, and smart collar GPS tracker.
2. **Veterinarian Portal (`/vet`)**:
   - Patient triage queue, live telemetry vitals HUD, SOAP consultation notes, digital prescription generator, and medical archive.
3. **Volunteer & Rescue Portal (`/volunteer`)**:
   - Emergency dispatch operations, live stray animal reports, lost pet sighting verification, and rescue achievement milestones.
4. **Administrator Portal (`/admin`)**:
   - Staff credentials roster, security event center, user moderation, system health audits, and Indian Standard Time (`hh:mm:ss a IST`) activity logs.

---

## 🏗️ Technical Architecture & Project Structure

```
lib/
├── core/                  # Design tokens, theme system, network clients, external actions
│   ├── config/            # App environment variables & Supabase bootstrap
│   ├── theme/             # Design System (tokens, color schemes, portal themes)
│   ├── utils/             # ExternalActions (maps, share, phone), date formatters
│   └── providers/         # Global Riverpod singletons
├── features/              # Feature-first Clean Architecture
│   ├── ai_services/       # Gemini 3.x REST engine, multimodal vision, speech sizers
│   ├── administrator/     # Staff management, audit logs, security, platform reports
│   ├── auth/              # Supabase Auth, OTP verification, role-based routing
│   ├── pet_owner/         # Pets, Health Passport, AI chat, Document Vault, community
│   ├── smart_collar/      # Live GPS map, geofencing, BLE telemetry
│   ├── veterinarian/      # Triage queue, consultations, prescriptions, treatment plans
│   └── volunteer_rescue/  # Emergency operations, rescue missions, community alerts
├── router/                # Declarative GoRouter routing & role-based authentication guards
└── shared/                # Reusable UI components, cards, buttons, loaders, empty states
```

- **Framework**: [Flutter 3.44.9](https://flutter.dev) (Dart 3.12.2)
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security, Realtime, Storage)
- **AI Engine**: Google Gemini 3.7 Flash & 3.8 Flash via direct REST & Supabase Edge Functions
- **Mapping**: OpenStreetMap & Flutter Map with Nominatim Reverse Geocoding
- **Hardware Integration**: Camera, Image Picker, Speech-to-Text, Share Plus, Path Provider, PDF Printing

---

## 🔒 Security & Environment Architecture

PetConnect AI enforces strict credential isolation:
- **Zero Secrets in Git**: Private API keys and server tokens are kept out of source code.
- **Client Access**: The Flutter app reads configurations at runtime from `.env` (strictly git-ignored).
- **Server-Side AI**: Gemini API keys for backend routines live in **Supabase Edge Function secrets** (`supabase secrets set GEMINI_API_KEY=...`).
- **Row-Level Security (RLS)**: Enforced across all Supabase PostgreSQL tables to guarantee pet records, medical data, and user messages are private to authorized accounts.

---

## 🛠️ Getting Started & Local Development

### Prerequisites
- **Flutter SDK**: `^3.44.0`
- **Dart SDK**: `^3.12.0`
- **Supabase Account**: ([supabase.com](https://supabase.com))
- **Google Gemini API Key**: ([Google AI Studio](https://aistudio.google.com/))

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Antony0610/Pet_Connect_Ai.git
   cd Pet_Connect_Ai/petconnect_ai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the `petconnect_ai/` directory (see `.env.example`):
   ```env
   APP_ENV=dev
   APP_NAME=PetConnect AI (Dev)
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GEMINI_API_KEY=your-gemini-api-key
   AI_EDGE_FUNCTION_URL=https://your-project.supabase.co/functions/v1/ai-assistant
   ```

4. **Verify static analysis:**
   ```bash
   flutter analyze
   ```
   *(Expected output: No issues found!)*

5. **Run on an Android device or emulator:**
   ```bash
   flutter run
   ```

6. **Build production release APK:**
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be generated at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
