# 🐾 PetConnect AI — Next-Gen Intelligent Pet Care Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%2B%20Auth%20%2B%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-3.1%20Flash%20Lite%20%26%203.7%20Flash-8E75B2?logo=google)](https://deepmind.google/technologies/gemini/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20Riverpod-orange)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**PetConnect AI** is a production-grade, AI-powered pet care and safety platform. It seamlessly unites companion health tracking, IoT smart collar telemetry, multimodal veterinary AI triage, real clinical EMR workflows, and a vibrant community across 4 interconnected portals.

---

## 🚀 Key Feature Highlights

### 1. 🤖 Multimodal AI Health Assistant & Visual Scribe
- **Prioritized Gemini 3.x Engine**: Ultra-fast latency and high-capacity multimodal intelligence:
  - ⚡ `gemini-3.7-flash` (Flagship multimodal model with deep clinical reasoning)
  - 🚀 `gemini-3.1-flash-lite` (Sub-1.2s ultra-low latency engine for instant answers)
  - ✨ `gemini-3.6-flash` (High-throughput multimodal intelligence)
  - 🌟 `gemini-3.5-flash` (High-precision visual diagnostics)
  - 🧠 `gemini-2.5-flash` (High-quota reliable fallback baseline)
- **Computer Vision Symptom Inspection**: Direct camera and gallery photo analysis assessing dermatological symptoms, facial fold hygiene, coat condition, and nutrition labels with structured clinical insights.
- **Bilingual Voice Scribe Toggle `[EN | ML]`**: Interactive language toggle enabling speech dictation in both **Malayalam (`ml_IN`)** and **Indian English (`en_IN`)**.
- **ChatGPT-Style Floating Navigation**: Translucent frosted-glass quick scroll button with reading position retention.

### 2. 🦾 Animated 3D Mascot Companion & Emotes
- **4 Selectable Character Avatars**:
  - 🤖 **Classic Aero Bot** — Sleek aerodynamic companion with glowing neon accents
  - 🐱 **Cyber Neko** — Playful feline robotic avatar with dynamic ear motions
  - 🐶 **Cyber Pup** — Loyal canine companion with responsive alert poses
  - 🌌 **Astral Bot** — Cosmic holographic guardian with deep gradient rings
- **Dynamic Emote Visor**: Real-time expressions (`^ ‿ ^`, `★ ‿ ★`, `♥ ‿ ♥`, `• ‿ •`, `o ‿ o`) that react to conversation flow and AI synthesis states.
- **Elastic Physics**: Bouncy spring entrance and smooth idle floating animations.

### 3. 🏥 End-to-End Clinical EMR & Consultation Suite
- **Real Patient Records**: Complete medical profiles for registered pets (`chikku`, `Harly`, `joe`, `miavv`) loaded directly from Supabase with zero mock data.
- **Smart Collar Live Telemetry HUD**: Species-aware baseline vitals (canine vs feline heart rate, respiratory rate, 38.6°C normothermic temp, BLE 5.3 + LTE-M status).
- **SOAP Clinical Consultation Workspace**: Attending veterinarians can document Subjective, Objective, Assessment, and Plan notes with real-time AI assistance.
- **Automated Invoicing & Digital Prescription PDF**:
  - Auto-calculates itemized fees and pharmacy line items.
  - Generates official clinical PDFs with council registration numbers and clinic certification.
  - Instantly archives documents into the pet's **Document Vault** and **Medical History**.
- **Document Vault Management**: PDF preview, native device sharing, and direct document deletion for complete record control.

### 4. 📅 Direct Appointment Booking & Triage Queue
- **Owner-to-Clinic Booking Sheet**: Pet owners can browse verified clinic veterinarians, pick preferred dates/time slots, select priority triage levels, and book consultations with one tap.
- **Real Practitioner Triage Queue**: Live queue synchronized with the database; practitioners can admit registered patients with honest sector status alerts.

### 5. 💬 Modern Messenger & Community Hub
- **1-on-1 & Group Chats**: Real-time messaging with delivery receipts, file sharing, and category channels (`Rescue`, `Breed Club`, `General Care`).
- **Profile Preview Modals**: Tap any avatar in direct or group chats to view verified user badges, contact info, and bio details.
- **Automated Cross-Portal Notifications**: Follow actions and direct messages instantly trigger persistent notifications across all 4 portals.

### 6. 🛰️ IoT Smart Collar Telemetry & Geofencing
- **Dynamic OpenStreetMap**: Automatically centers on the user’s real-world geocoded city without static coordinate dependencies.
- **Safe Zone Geofencing**: Configurable metric radius (50m - 1000m) with tap-to-relocate perimeter controls.
- **Emergency Lost Pet Radar**: Broadcast alerts to nearby volunteer rescues and community members with real-time updates.

### 7. ⏱️ Indian Standard Time (IST) Administration
- **Synchronized Platform Time**: Administrator Audit Logs, Security Event Center, and Platform Activity streams are fully synchronized to Indian Standard Time (IST, UTC+05:30) with explicit `hh:mm:ss a IST` formatting.

---

## 🏛️ Multi-Portal Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       PetConnect AI                         │
├──────────────┬──────────────┬───────────────┬───────────────┤
│  Pet Owner   │ Veterinarian │ Volunteer &   │ Administrator │
│    Portal    │    Portal    │ Rescue Portal │    Portal     │
└──────────────┴──────────────┴───────────────┴───────────────┘
```

1. **Pet Owner Portal (`/owner`)**:
   - Health Passport, vaccination timeline, consultation booking, AI symptom scanner, Document Vault, and smart collar tracker.
2. **Veterinarian Portal (`/vet`)**:
   - Patient triage queue, live telemetry vitals, SOAP consultation workspace, digital prescription builder, and treatment plans.
3. **Volunteer & Rescue Portal (`/volunteer`)**:
   - Emergency dispatch operations, live stray rescue cases, lost pet alerts, and volunteer achievements.
4. **Administrator Portal (`/admin`)**:
   - Roster staff management, security event center, user moderation, system health audits, and IST-formatted logs.

---

## 🏗️ Technical Stack & Project Structure

```
lib/
├── core/                  # Design tokens, extensions, network clients, external actions
│   ├── config/            # App environment variables & Supabase bootstrap
│   ├── theme/             # Design System (tokens, color schemes, portal themes)
│   ├── utils/             # ExternalActions (maps, share, phone), date formatters
│   └── providers/         # Global Riverpod singletons
├── features/              # Feature-first Clean Architecture
│   ├── ai_services/       # Gemini 3.x REST engine, multimodal vision, speech sizers
│   ├── administrator/     # Staff management, audit logs, security, platform reports
│   ├── auth/              # Supabase Auth, OTP login, role routing
│   ├── pet_owner/         # Pets, Health Passport, AI chat, Document Vault, community
│   ├── smart_collar/      # Live GPS map, geofencing, BLE telemetry
│   ├── veterinarian/      # Triage queue, consultations, prescriptions, treatment plans
│   └── volunteer_rescue/  # Emergency operations, rescue missions, community alerts
├── router/                # Declarative GoRouter routing & role-based guards
└── shared/                # Universal UI components, cards, buttons, loaders
```

- **Framework**: [Flutter 3.44.9](https://flutter.dev) (Dart 3.12.2)
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security, Realtime, Storage)
- **AI Models**: Google Gemini 3.7 Flash, Gemini 3.1 Flash-Lite, Gemini 1.5 Pro via direct REST API
- **Native Interop**: Camera, Image Picker, Speech-to-Text, Share Plus, Path Provider, PDF Printing

---

## 🛠️ Getting Started

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

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in `petconnect_ai/`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GEMINI_API_KEY=your-gemini-api-key
   ```

4. **Verify static analysis:**
   ```bash
   flutter analyze
   ```
   *(Expected output: No issues found!)*

5. **Run the application:**
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
