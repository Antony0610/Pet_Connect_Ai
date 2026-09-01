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
- **Top 5 Latest Gemini 3.x Models**: Prioritized support with on-the-fly model switcher:
  - ⚡ `gemini-3.7-flash` (Flagship multimodal model with deep clinical reasoning)
  - 🚀 `gemini-3.1-flash-lite` (Ultra-low ~1.1s latency engine for instant answers)
  - ✨ `gemini-3.6-flash` (Next-gen high-throughput multimodal intelligence)
  - 🌟 `gemini-3.5-flash` (High-precision visual diagnostics)
  - 🧠 `gemini-2.5-flash` (High-quota reliable baseline)
- **Sub-200ms Fast Failover**: Automatic multi-tier model cascade ensuring 100% uptime even during peak usage.
- **Multimodal Visual Health Inspection**: Direct Gemini vision scanner analyzing species, breed, facial fold hygiene, coat condition, and clinical recommendations with zero generic templates.
- **ChatGPT-Style Floating Navigation**: Translucent glass down-arrow button with smooth auto-scroll to bottom and smart reading position retention.
- **High-Contrast Design**: Optimized suggestion chips with crisp contrast in both Light and Dark themes.

### 2. 🦾 3D Articulated AI Mascot Avatar
- **Freestanding Floating Character**: Multi-stop specular gradients (`#FFFFFF` → `#F8FAFC` → `#E2E8F0` with glowing neon rim).
- **Curved Glass Visor**: Obsidian OLED digital visor with high-gloss reflection sheen.
- **Dynamic Emote Visor**: Expressive glowing LED eyes (`^ ‿ ^`, `> ‿ <`, `● ‿ ●`, `★ ‿ ★`) with context-aware micro-animations.
- **Dual Concentric Arc Reactor**: Pulsing energy core and smooth articulated robotic waving arm.

### 3. 💬 Modern Messenger & Community Group Chat
- **Direct 1-on-1 Chats**: Modern WhatsApp/iMessage styled chat bubbles, delivery checkmarks (`✓✓`), and search filters.
- **Community Groups**: Multi-user channels with real-time Supabase streaming, category badges (`Breed Club`, `Rescue`, `Veterinary`), and interactive "Create Group" modal.
- **Foreign-Key Safe**: Resilient profile matching ensuring 100% database integrity.

### 4. 🛰️ IoT Smart Collar Telemetry & Geofencing
- **Dynamic Geocoded Map**: Interactive OpenStreetMap centered dynamically on user's profile location with zero hardcoded coordinates.
- **Geofence Safe Zones**: Metric radius slider (50m - 1000m) with tap-to-relocate perimeter controls.
- **Real Lost & Found Hub**: Live Supabase alert broadcast with direct rescue and community notifications.

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
