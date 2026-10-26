# Smart Collar & Telemetry Architecture

## 1. Overview & R&D Prototype Framing

PetConnect integrates IoT telemetry, GPS tracking, geofencing, and emergency recovery mechanisms through an **ESP32-based Smart Collar Architecture**.

> [!NOTE]
> **R&D Prototype Status:** The physical collar hardware is architected as an active **Research & Development (R&D) prototype specification**. The platform provides full end-to-end hardware simulation, live mobile HUD tracking, and an interactive **Single Prototype Tag Simulator (`TAG-PROTOTYPE-001`)** across both mobile and web surfaces.

---

## 2. System Architecture & Data Flow

```
┌────────────────────────────────────────────────────────┐
│              ESP32 Smart Collar (Prototype)            │
│  - ESP32-WROOM-32 / ESP32-C3 Microcontroller           │
│  - GNSS/GPS Receiver (NEO-6M / u-blox SAM-M8Q)         │
│  - BLE 5.3 (GATT Server for Provisioning & Pairing)    │
│  - 2.4 GHz 802.11b/g/n WiFi / LTE-M Telemetry Uplink   │
│  - Buzzer & Strobe LED Actuators                       │
└──────────────────────────┬─────────────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             │                           │
        BLE 5.3 Handshake           HTTPS Telemetry
      (Setup & Safe Zones)        (30s GPS / 5m Health)
             │                           │
             ▼                           ▼
┌─────────────────────────┐  ┌───────────────────────────┐
│  Flutter Mobile App     │  │   Supabase Cloud Platform │
│  - Live OSM Map Tracking│  │  - PostgreSQL collar_logs │
│  - Safe Zone Geofencing │  │  - Realtime Telemetry Hub │
│  - Remote Buzzer/Strobe │  │  - Emergency Broadcast SOS│
└────────────┬────────────┘  └─────────────┬─────────────┘
             │                             │
             └──────────────┬──────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│           Emergency Recovery & Public Web Portal       │
│  - Physical QR Code Collar Medal / Tag                 │
│  - Single Prototype Tag Simulator (TAG-PROTOTYPE-001)  │
│  - Zero-App Web Dossier (/emergency, /missing)         │
└────────────────────────────────────────────────────────┘
```

---

## 3. Connectivity Protocols

### 3.1 Bluetooth Low Energy (BLE 5.3) — Pairing & Local Control
- **Purpose**: Initial collar commissioning, WiFi credential transfer, safe zone local cache sync, and direct proximity buzzing.
- **Protocol**: Custom BLE GATT Service.
- **Advertised Service UUID**: `0000FFF0-0000-1000-8000-00805F9B34FB`

| Characteristic | UUID | Type | Description |
| :--- | :--- | :--- | :--- |
| **WiFi SSID** | `0000FFF1-...` | Write | Target 2.4 GHz access point SSID |
| **WiFi Password** | `0000FFF2-...` | Write | Encrypted network passphrase |
| **Device Token** | `0000FFF3-...` | Write | Signed collar auth bearer token |
| **Telemetry Notify** | `0000FFF4-...` | Read/Notify | Real-time sensor stream (vitals, GPS) |
| **Actuator Command** | `0000FFF5-...` | Write | `0x01` (Buzzer ON), `0x02` (LED Strobe) |

### 3.2 WiFi / Cellular Uplink — Remote Cloud Telemetry
- **Purpose**: Continuous telemetry streaming to cloud backend.
- **Protocol**: HTTPS REST payloads pushed to Supabase Edge Functions / PostgreSQL.
- **Intervals**:
  - Standard Mode: GPS every 30 seconds, vitals every 5 minutes.
  - Emergency Lost Mode: GPS every 5 seconds, high-intensity beaconing.

---

## 4. Single Prototype Tag Simulator (`TAG-PROTOTYPE-001`)

To enable seamless testing and live demonstrations without physical hardware on hand, the platform specifies a single authoritative prototype tag:

- **Tag Identifier**: `TAG-PROTOTYPE-001`
- **Simulated Pet Profile**: Fully hydrated companion record with active vaccination status, emergency owner contacts, and known allergies.
- **Verification Flow**:
  1. Finder or tester taps the **Simulate QR Scan** button on the Web Portal or enters `TAG-PROTOTYPE-001`.
  2. Resolves immediately to `/emergency/TAG-PROTOTYPE-001`.
  3. Displays live medical emergency profile, immediate one-tap owner calling, WhatsApp sighting dispatch, and emergency veterinary history.

### Web QR Simulator Component (`web_portal/src/components/QrSimulatorModal.tsx`)
The React 19 web portal includes a dedicated modal that:
- Prominently showcases the collar hardware as an **R&D prototype**.
- Generates live scannable QR matrix for phone camera testing.
- Offers instant click-to-simulate buttons that transition to emergency and vaccination verification views without requiring app installation.

---

## 5. Live Mobile HUD & OpenStreetMap Pipeline

The Pet Owner portal features a comprehensive tracking screen (`SmartCollarDashboardScreen`):

### 5.1 OpenStreetMap & Flutter Map
- **Map Renderer**: `flutter_map` leveraging OpenStreetMap vector tile layers (eliminates restrictive proprietary map key dependencies).
- **Reverse Geocoding**: Integrated with OpenStreetMap's Nominatim service for real-time street, city, and neighborhood translation.
- **Dynamic Trail Polylines**: Visualizes historical path over the past 24 hours with gradient trail decay.

### 5.2 Active Telemetry HUD
Continuously monitors collar diagnostic sensors:
- 🔋 **Battery Level**: Percentage, estimated time remaining, and power saving modes.
- 📶 **Signal Quality**: BLE 5.3 RSSI indicator and LTE-M connection strength.
- 🌡️ **Normothermic Temperature**: Real-time ambient and animal body temperature sensing (target: 38.6°C).
- 🏃 **Activity Tracker**: Step count, rest duration, and vigorous exercise bursts.

---

## 6. Geofencing & Lost Pet Radar Protocol

### 6.1 Safe Zone Boundary Configuration
- Configurable radius: **50m to 1,000m** around home or current location.
- Boundary violation triggers immediate local push notification and high-priority collar alert.

### 6.2 Emergency Lost Mode
When the user taps **"Enable Lost Mode"**:
1. **Collar Command**: Collar transitions to high-frequency GPS pinging (every 5 seconds) and activates low-power LED strobe for night visibility.
2. **Community Radar Broadcast**: Pushes emergency lost pet notice to nearby registered volunteers, shelters, and pet owners within a 5km radius.
3. **Public Dossier Activation**: Flips the pet's public emergency web page (`/missing/:id`) to `CRITICAL ALERT` status with live sighting submission form.
