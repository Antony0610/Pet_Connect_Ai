# Smart Collar & Telemetry Architecture

## 1. Overview & Project Phase Separation

PetConnect AI integrates IoT telemetry, GNSS location tracking, radial geofencing, and emergency recovery mechanisms through an engineered **Smart Collar Architecture**.

> [!IMPORTANT]
> **Phase Separation & Prototype Status:**
> - **Phase 1 (Software Platform — Completed):** Mobile and web tracking dashboard, OpenStreetMap HUD, radial geofence alerts, Supabase realtime telemetry pipeline, and the authoritative **Single Prototype Tag Simulator (`TAG-PROTOTYPE-001`)**.
> - **Phase 2 (Physical Collar Prototyping — Planned):** Physical manufacturing, PCB assembly, and live firmware integration targeting the frozen hardware bill of materials below.
> - **Integrity Rule:** Simulated readings in Phase 1 software must never be presented as physical sensor data. Location and activity tracking are safety and wellness markers, **NOT** medical diagnostics.

---

## 2. Frozen Hardware Specification (Phase 2 Prototype)

The hardware specification is frozen to prevent scope creep, excessive power consumption, and unverified component substitutions:

| Subsystem | Frozen Component Selection | Specification & Role |
| :--- | :--- | :--- |
| **Main Microcontroller** | **Seeed Studio XIAO ESP32-C6** | Ultra-compact RISC-V controller. Coordinates I²C sensors, monitors active-LOW SOS button, switches buzzer via NPN transistor, and interfaces with cellular modem via UART. |
| **GNSS & Cellular Modem** | **ADIY EC200U Development Board** | Unified Quectel EC200U module providing both GNSS location (GPS/GLONASS) and LTE Cat 1 cellular connectivity. Eliminates separate GPS receivers. |
| **Motion & Activity Sensing** | **LIS2DU12 Accelerometer Breakout** | 3-axis ultra-low-power accelerometer over shared I²C bus. *(Reconciled from older notes referencing LIS3DH; latest wiring guide artwork specifies LIS2DU12).* |
| **Battery Monitoring** | **MAX17048 Fuel Gauge Breakout** | Accurate State of Charge (SOC %) and voltage monitoring via dedicated `BAT/CELL` connection to the Li-Po battery positive terminal over I²C. |
| **Battery & Power** | **1S 3.7 V Nominal Li-Po Cell** | Single-cell Li-Po. *(Saved drawings specify both 700 mAh and 1000 mAh examples; exact capacity remains a pending BOM confirmation based on enclosure size).* |
| **Battery Protection** | **1S Li-Po Protection Board (5A class)** | Protects cell against over-discharge (<2.8V) and over-current (>5A). *(Protection is NOT a charger; requires separate 1S CC/CV 4.2V charging circuit).* |
| **SOS Emergency Input** | **Momentary Pushbutton (Active-LOW)** | User-triggered physical emergency input connected to GPIO with internal pull-up. Released = HIGH, Pressed = LOW. |
| **Audible Alert** | **Piezo Buzzer + NPN Transistor Driver** | 2N2222 / PN2222A transistor driver with ~1 kΩ base resistor. **Never** driven directly from GPIO pin. |
| **Modem Power Control** | **SPST Slide Switch** | Dedicated switch on the EC200U high-current power path to prevent drain during storage or bench testing. |

### Explicit Exclusions (Not in Frozen Specification)
- ❌ **No Heart-Rate Sensor** (PPG).
- ❌ **No SpO₂ Pulse Oximeter**.
- ❌ **No Core-Body-Temperature Sensor**.
- ❌ **No Camera or Microphone**.
- ❌ **No RGB Status LED** (not included in the frozen wiring guide).
- ❌ **No Secondary GPS Module** (GNSS is handled entirely by the ADIY EC200U).
- ❌ **No Diagnostic Claims** (telemetry monitors activity and position, never diagnoses medical illness).

---

## 3. System Architecture & Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│             PetConnect AI Smart Collar (Phase 2 Hardware)              │
│                                                                        │
│  LIS2DU12 Accelerometer ─── I²C (SDA D4/GPIO22, SCL D5/GPIO23) ─────┐  │
│  MAX17048 Fuel Gauge   ─── I²C (SDA D4/GPIO22, SCL D5/GPIO23) ─────┤  │
│  SOS Pushbutton        ─── Active-LOW (D2/GPIO2 with pull-up) ─────┤  │
│  Piezo Buzzer Driver   ─── Active-HIGH NPN (D3/GPIO21 + 1kΩ) ──────┤  │
│                                                                     │  │
│                     Seeed Studio XIAO ESP32-C6                      │  │
│                                 │                                   │  │
│               UART (D6/GPIO16 TX ──▶ EC200U RX)                     │  │
│               UART (D7/GPIO17 RX ◀── EC200U TX)                     │  │
│                                 ▼                                   │  │
│             ADIY EC200U Cellular & GNSS Breakout Board              │  │
│             (Quectel EC200U LTE Cat 1 + Embedded GNSS)              │  │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  │ LTE Cat 1 Cellular Uplink
                                  │ (JSON Telemetry over HTTPS / MQTT)
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Supabase Cloud Platform                         │
│  - Edge Function: collar-ingest (Validates Schema v1 & Device Token)   │
│  - PostgreSQL: collar_telemetry table with Row Level Security (RLS)    │
│  - Realtime: Broadcasts location updates to authorized pet owner       │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   PetConnect AI Mobile & Web Surfaces                  │
│  - Flutter Mobile App: Live OpenStreetMap HUD, Radial Geofencing       │
│  - Finder Web Portal: /emergency/:tagId instant medical dossier        │
│  - Simulator: TAG-PROTOTYPE-001 digital twin for bench testing         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Frozen GPIO and Bus Mapping

Baseline pinout defined for the **Seeed Studio XIAO ESP32-C6**:

| XIAO Pin | MCU GPIO | Direction | Assigned Function | Electrical & Firmware Notes |
| :---: | :---: | :---: | :--- | :--- |
| **D2** | **GPIO2** | Input | **SOS Pushbutton** | Active LOW. Pushbutton connects GPIO2 to GND when pressed. Internal pull-up enabled in firmware. Debounced. |
| **D3** | **GPIO21** | Output | **Buzzer Driver** | Active HIGH. Controls NPN transistor base through ~1 kΩ series resistor. |
| **D4** | **GPIO22** | I/O | **I²C SDA** | Shared I²C data line for both **LIS2DU12** and **MAX17048**. |
| **D5** | **GPIO23** | Output | **I²C SCL** | Shared I²C clock line for both **LIS2DU12** and **MAX17048**. |
| **D6** | **GPIO16** | Output | **UART TX (XIAO → EC200U)** | Connects to EC200U UART RX. Verify 3.3V logic level compatibility before connecting. |
| **D7** | **GPIO17** | Input | **UART RX (XIAO ← EC200U)** | Connects from EC200U UART TX. Common ground required. |
| **D8** | **GPIO19** | — | **Reserved** | Reserved for future expansion. |
| **D9** | **GPIO20** | — | **Reserved** | Reserved for future expansion. |

### Critical Electrical Safety Warnings
1. **EC200U Peak Current:** Cellular transmission bursts draw up to ~2.0 A. **NEVER** power the EC200U from the XIAO 3.3V pin. It must be powered directly from the battery rail.
2. **MAX17048 BAT/CELL Node:** Must connect directly to the Li-Po battery positive terminal, **NEVER** to the regulated 3.3V rail.
3. **Common Ground:** All modules must share a solid common ground.
4. **Buzzer Protection:** Buzzer is driven by an NPN transistor, never directly from an ESP32 GPIO pin.

---

## 5. Telemetry Contract (Schema Version 1)

All telemetry payloads sent to the backend conform to this structured schema:

```json
{
  "schema_version": 1,
  "device_id": "COLLAR-PROTOTYPE-001",
  "pet_id": "pet-registered-uuid",
  "firmware_version": "0.1.0",
  "recorded_at": "2026-10-26T16:45:00Z",
  "location": {
    "valid": true,
    "latitude": 9.9816,
    "longitude": 76.2999,
    "fix_time": "2026-10-26T16:44:58Z",
    "accuracy_m": 3.5
  },
  "motion": {
    "valid": true,
    "accel_x": 0.04,
    "accel_y": 0.98,
    "accel_z": 0.12,
    "unit": "g"
  },
  "battery": {
    "fuel_gauge_percent": 87.5,
    "voltage_v": 4.02,
    "valid": true
  },
  "device_status": {
    "sos_pressed": false,
    "modem_connected": true,
    "gnss_fix_valid": true,
    "sensor_fault": false
  }
}
```

---

## 6. Single Prototype Tag Simulator (`TAG-PROTOTYPE-001`)

To enable seamless testing, automated validation, and live presentations without physical hardware on hand, the platform specifies a single authoritative prototype tag:

- **Tag Identifier**: `TAG-PROTOTYPE-001`
- **Simulated Pet Profile**: Fully hydrated companion record with active vaccination status, emergency owner contacts, and known allergies.
- **Verification Flow**:
  1. Finder or tester taps the **Simulate QR Scan** button on the Web Portal or enters `TAG-PROTOTYPE-001`.
  2. Resolves immediately to `/emergency/TAG-PROTOTYPE-001`.
  3. Displays live medical emergency profile, immediate one-tap owner calling, WhatsApp sighting dispatch, and emergency veterinary history.

---

## 7. Live Mobile HUD & OpenStreetMap Pipeline

The Pet Owner portal features a comprehensive tracking screen (`SmartCollarDashboardScreen`):

### 7.1 OpenStreetMap & Flutter Map
- **Map Renderer**: `flutter_map` leveraging OpenStreetMap tile layers (eliminates proprietary map API keys).
- **Reverse Geocoding**: Integrated with OpenStreetMap Nominatim service for real-time address translation.
- **Dynamic Trail Polylines**: Visualizes historical path over the past 24 hours with gradient decay.

### 7.2 Active Telemetry HUD
Continuously monitors collar diagnostic sensors:
- 🔋 **Battery Level**: MAX17048 Fuel gauge percentage and cell voltage.
- 📶 **Signal Quality**: LTE Cat 1 connection status and GNSS fix validity.
- 🏃 **Activity Tracker**: LIS2DU12 3-axis motion samples categorized into rest, walking, and active movement.
- 🚨 **Emergency SOS**: Immediate alert if the physical SOS pushbutton is triggered.

---

## 8. Geofencing & Lost Pet Radar Protocol

### 8.1 Safe Zone Boundary Configuration
- Configurable radius: **50m to 1,000m** around home or current location.
- Boundary violation triggers immediate local push notification and high-priority collar alert.

### 8.2 Emergency Lost Mode
When the user taps **"Enable Lost Mode"**:
1. **Collar Command**: Collar transitions to high-frequency GNSS pinging (every 5 seconds) and enables buzzer beaconing.
2. **Community Radar Broadcast**: Pushes emergency lost pet notice to nearby registered volunteers, shelters, and pet owners within a 5km radius.
3. **Public Dossier Activation**: Flips the pet's public emergency web page (`/missing/:id`) to `CRITICAL ALERT` status with live sighting submission form.
