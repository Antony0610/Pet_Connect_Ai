# PetConnect AI — Frozen Smart Collar Hardware Specification

> **Purpose:** This document is the project-specific hardware handover and specification for PetConnect AI Phase 2. It defines the authoritative component selections, GPIO mappings, power routing, telemetry contract, and safety guidelines derived from the project's engineering diagrams.
> 
> **Project Phase Separation:**
> - **Phase 1 (Current):** Complete software platform (Flutter mobile app, Supabase backend, PostgreSQL RLS, Gemini AI Assistant & Triage, OpenStreetMap HUD, and authoritative `TAG-PROTOTYPE-001` test simulator).
> - **Phase 2 (Hardware Integration):** Physical smart collar prototyping, PCB assembly, firmware bring-up, and live hardware telemetry ingestion.
> 
> **Important:** This document records the planned/frozen prototype design. Simulated readings in software must never be presented as real hardware data.

---

## 1. Core Hardware Bill of Materials (BOM)

| Function | Project-Selected Component | Role in Prototype |
| :--- | :--- | :--- |
| **Main Controller** | **Seeed Studio XIAO ESP32-C6** | Runs collar firmware, reads sensors via I²C, monitors active-LOW SOS input, switches buzzer via NPN transistor, and communicates with cellular/GNSS modem via UART. |
| **GNSS + Cellular** | **ADIY EC200U Development Board** | Integrated GNSS location and LTE Cat 1 cellular communication. Single unified module (Quectel EC200U). Eliminates separate GPS receivers. |
| **Motion Sensing** | **LIS2DU12 Accelerometer Breakout** | Ultra-low-power 3-axis motion and activity sensing over shared I²C bus. *(Reconciled from earlier planning notes referencing LIS3DH; latest wiring guide specifies LIS2DU12).* |
| **Battery Monitoring** | **MAX17048 Fuel-Gauge Breakout** | ModelGauge fuel-gauge IC providing accurate State of Charge (SOC %) and cell voltage over shared I²C bus via dedicated `BAT/CELL` connection to Li-Po positive terminal. |
| **Battery** | **1S 3.7 V Nominal Li-Po Cell** | Powers the wearable prototype. *(Saved diagrams show both 700 mAh and 1000 mAh examples; exact capacity remains a pending BOM confirmation).* |
| **Battery Protection** | **1S Li-Po Protection Board (5A class)** | Over-discharge, over-charge, and short-circuit protection. *(Note: Protection PCB is NOT a charger; requires dedicated 1S CC/CV 4.2V charging circuit).* |
| **SOS Emergency Input** | **Momentary Pushbutton (Active-LOW)** | User-triggered physical emergency input connected to GPIO with internal pull-up. Released = HIGH, Pressed = LOW. |
| **Audible Alert** | **Piezo Buzzer + NPN Transistor Driver** | Transistor-switched buzzer driver (2N2222 / PN2222A or equivalent with ~1 kΩ base resistor). Never driven directly from microcontroller GPIO. |
| **Modem Power Control**| **SPST Slide Switch** | Physical switch in the EC200U battery power rail to isolate modem during bench testing or low-power storage. |

### Explicitly Excluded (Do Not Add)
- ❌ **No Heart-Rate Sensor** (PPG).
- ❌ **No SpO₂ Pulse Oximeter**.
- ❌ **No Core Body Temperature Sensor**.
- ❌ **No Camera or Microphone**.
- ❌ **No RGB Status LED** (not in frozen design).
- ❌ **No Secondary GPS Module** (GNSS is provided directly by the ADIY EC200U).
- ❌ **No Clinical Medical Claims** (location and activity telemetry are wellness/safety markers, NOT medical diagnostics).

---

## 2. Frozen GPIO and Bus Mapping

Baseline pinout defined for the **Seeed Studio XIAO ESP32-C6**:

| XIAO Pin | MCU GPIO | Direction | Assigned Function | Electrical & Firmware Notes |
| :---: | :---: | :---: | :--- | :--- |
| **D2** | **GPIO2** | Input | **SOS Pushbutton** | Active LOW. Pushbutton connects GPIO2 to GND when pressed. Internal pull-up enabled in firmware. Debounced (short vs long press). |
| **D3** | **GPIO21** | Output | **Buzzer Driver** | Active HIGH. Controls NPN transistor base through ~1 kΩ series resistor. Transistor pulls buzzer negative terminal to GND. |
| **D4** | **GPIO22** | I/O | **I²C SDA** | Shared I²C data line for both **LIS2DU12** and **MAX17048**. Check breakout pull-ups. |
| **D5** | **GPIO23** | Output | **I²C SCL** | Shared I²C clock line for both **LIS2DU12** and **MAX17048**. Check breakout pull-ups. |
| **D6** | **GPIO16** | Output | **UART TX (XIAO → EC200U)** | Connects to EC200U UART RX. Verify 3.3V logic level compatibility before connecting. |
| **D7** | **GPIO17** | Input | **UART RX (XIAO ← EC200U)** | Connects from EC200U UART TX. Common ground required. |
| **D8** | **GPIO19** | — | **Reserved** | Reserved for future expansion. Do not assign without hardware review. |
| **D9** | **GPIO20** | — | **Reserved** | Reserved for future expansion. Do not assign without hardware review. |

### UART Crossing Summary
- `XIAO D6 (GPIO16 TX)` ───▶ `EC200U UART RX`
- `XIAO D7 (GPIO17 RX)` ◀─── `EC200U UART TX`
- Common GND between XIAO and EC200U boards is mandatory.

---

## 3. Power Architecture & Wiring Rules

```
                      ┌──────────────────────────────────────────────┐
                      │          1S 3.7V Nominal Li-Po Cell          │
                      │            (700 mAh / 1000 mAh)              │
                      └──────────────────────┬───────────────────────┘
                                             │
                                  ┌──────────┴──────────┐
                                  │ 1S Protection Board │ (5A Overcurrent / Short-circuit)
                                  └──────────┬──────────┘
                                             │
                   ┌─────────────────────────┼─────────────────────────┐
                   │                         │                         │
                   ▼                         ▼                         ▼
            ┌──────────────┐         ┌──────────────┐           ┌──────────────┐
            │  XIAO BAT+   │         │ MAX17048     │           │ SPST Switch  │
            │  (VBAT Pin)  │         │ BAT/CELL Pin │           └──────┬───────┘
            └──────────────┘         └──────────────┘                  │
                                                                       ▼
                                                                ┌──────────────┐
                                                                │ ADIY EC200U  │
                                                                │ VBAT Input   │
                                                                └──────────────┘
```

### Critical Electrical Rules:
1. **EC200U Dedicated Power:** The cellular modem can draw transmit burst peaks up to ~2.0 A. **NEVER** power the EC200U from the XIAO 3.3V LDO regulator output. It must be powered directly from the protected battery rail via the SPST slide switch.
2. **MAX17048 Sensing Node:** The `BAT/CELL` pin on the MAX17048 fuel gauge breakout must connect to the **battery positive node**, never to the regulated 3.3V rail.
3. **Common Ground:** All subsystems (XIAO ESP32-C6, ADIY EC200U, LIS2DU12, MAX17048, buzzer driver) must share a common system ground plane.
4. **Protection vs Charging:** The 1S protection PCB prevents dangerous over-discharge (<2.8V) and over-current (>5A), but does **NOT** regulate charging. Use a dedicated 1S CC/CV charger (4.2V cutoff).

---

## 4. Proposed Telemetry Schema (Version 1)

This versioned JSON contract defines the data shape transmitted over LTE Cat 1 to the PetConnect AI backend:

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

## 5. Items Flagged for Final BOM Confirmation

The following hardware details are explicitly flagged for bench verification before final physical manufacturing:
1. **Battery Capacity:** Saved diagrams specify both 700 mAh and 1000 mAh. Actual cell choice depends on physical enclosure dimensions and target collar weight.
2. **Accelerometer Part Number:** Reconciled from older notes referencing LIS3DH; latest wiring guide artwork labels LIS2DU12. Firmware drivers will target LIS2DU12.
3. **ADIY EC200U Board Revision:** Confirm physical pinout, carrier band support, and whether PWRKEY requires a pulse or tied state on the exact purchased board revision.
4. **Buzzer Transistor Pinout:** Confirm pinout of the chosen 2N2222 / PN2222A transistor package (E-B-C vs C-B-E varies across TO-92 variants).
