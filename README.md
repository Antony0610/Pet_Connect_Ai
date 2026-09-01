# 🐾 PetConnect AI — Next-Gen Intelligent Pet Care Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%2B%20Auth%20%2B%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-3.1%20Flash%20Lite%20%26%203.7%20Flash-8E75B2?logo=google)](https://deepmind.google/technologies/gemini/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20Riverpod-orange)](https://riverpod.dev)

**PetConnect AI** is a production-grade, AI-powered pet care and safety platform. It seamlessly unites companion health tracking, IoT smart collar telemetry, multimodal veterinary AI triage, and a vibrant pet community across 4 interconnected portals.

---

## 🚀 Key Feature Highlights

### 1. 🤖 Omni-Intelligence AI Assistant & Clinical Scanner
- **Ultra-Fast Sub-Second Streaming**: Multi-model failover cascade prioritizing `gemini-3.1-flash-lite` and `gemini-3.7-flash` with dynamic model badges.
- **ChatGPT-Style Floating Navigation**: Translucent glass down-arrow button with smooth auto-scroll to bottom and smart reading position retention.
- **Multimodal Visual Health Inspection**: Analyzes pet photos for dermatology, eyes, teeth, and posture differentials.
- **Ingredient & Plant Toxicity Engine**: Real-time canine/feline toxicity database with actionable clinical recommendations.
- **High-Contrast Design**: Optimized suggestion chips with crisp contrast in both Light and Dark themes.

### 2. 🦾 3D Articulated AI Mascot Avatar
- **Freestanding Floating Character**: Sits comfortably above navigation with zero intrusive button boxes.
- **Dynamic Emote Visor**: Expressive digital glowing LED eyes (`^ ‿ ^`, `> ‿ <`, `● ‿ ●`, `★ ‿ ★`) with context-aware micro-animations.
- **Articulated Waving Arm**: Smooth robotic shoulder pivot and continuous greeting gestures.
- **4 Distinct Cyber Themes**:
  - 🚀 *Classic Aero Bot* (High-gloss chassis with cyan arc reactor)
  - 🐱 *Cyber Neko Cat* (Mint ears & feline digital smiles)
  - 🐶 *Cyber Pup Dog* (Golden puppy ears & amber LED accents)
  - 🌌 *Chibi Astral Bot* (Cosmic orbital ring & starburst eyes)

### 3. 🛰️ IoT Smart Collar Telemetry & Geofencing
- **Live GPS Tracking**: Interactive map integration with dynamic battery, step count, and heart rate telemetry.
- **Geofence Safe Zones**: Circular safe perimeter management with real-time breach alerts.
- **Lost Pet Mode**: Instant beacon broadcast and high-resolution downloadable PDF lost pet poster generator.

### 4. 👥 Community Social Hub & Direct Messaging
- **Live Feed & Explore Gallery**: Rich photo grid and chronological companion stories.
- **Full Social Engine**: Real follower/following relationships, follower activity modal, and real-time social notifications.
- **Direct Messaging**: Dedicated messaging channels with other verified pet parents.
- **Public Profiles**: Dynamic bio editor, registered pet parent badges, and accurate Kerala & global geocoding.

### 5. 🏥 Multi-Portal Architecture
- **Pet Owner Portal**: Daily care routines, health passport PDF export, and vaccination schedules.
- **Veterinarian Portal**: Patient clinical triage, telemetry diagnostics, and treatment plans.
- **Volunteer & Rescue Portal**: Stray pet rescue case management and community lost-pet radar.
- **Administrator Portal**: User management, AI usage audit, and moderation controls.

---

## 🏗️ Architecture & Technology Stack

```
lib/
├── core/                  # Theme tokens, network clients, base UseCases, providers
│   ├── theme/             # Design System (tokens, color schemes, portal themes)
│   ├── network/           # Dio HTTP client, connection monitors
│   └── providers/         # Global Riverpod DI singletons
├── features/              # Feature-first Clean Architecture
│   ├── ai_services/       # Gemini API, multimodal vision, PDF report generation
│   ├── auth/              # Supabase Auth, OTP, UserProfile entity & models
│   ├── pet_owner/         # Pet profiles, health passport, community, AI hub
│   ├── smart_collar/      # Live GPS map, telemetry, geofence engine
│   ├── veterinarian/      # Clinical appointments, treatment plans
│   ├── volunteer_rescue/  # Rescue cases, lost-pet alerts
│   └── realtime/          # Supabase Realtime channel subscriptions
├── router/                # Declarative GoRouter routing & navigation
└── shared/                # Common UI tokens, glass containers, state widgets
```

- **Framework**: [Flutter 3.44.9](https://flutter.dev) (Dart 3.12.2)
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security, Auth, Storage, Edge Functions)
- **AI Models**: Google Gemini 3.1 Flash-Lite, Gemini 3.7 Flash, Gemini 1.5 Pro
- **Maps & Geolocation**: OpenStreetMap / Flutter Map with accurate reverse-geocoding

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK `^3.44.0`
- Dart SDK `^3.12.0`
- A Supabase Project ([supabase.com](https://supabase.com))
- Google Gemini API Key ([Google AI Studio](https://aistudio.google.com/))

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
   dart analyze
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

6. **Build production release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
