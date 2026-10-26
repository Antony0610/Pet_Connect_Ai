# PetConnect AI — Frozen Smart Collar Hardware Specification for Antigravity

> **Purpose:** This is the project-specific hardware handover for Antigravity. It replaces generic smart-collar suggestions. Use the actual component choices, GPIO mapping, and wiring decisions below when working on the PetConnect AI Phase 2 collar.
> 
> **Project Phase:** Phase 1 is the software platform. The physical collar and live hardware integration belong to Phase 2.
> 
> **Important:** Treat this as the intended/frozen prototype design from the existing PetConnect AI hardware planning materials—not proof that the physical device is already assembled or tested. Do not invent other sensors or substitute boards without explicitly flagging the proposed change and asking for approval.

---

## 1. Core Hardware Design — Use These Components

| Function | Project-Selected Component | Role in Prototype |
| :--- | :--- | :--- |
| **Main Controller** | **Seeed Studio XIAO ESP32-C6** | Runs collar firmware, reads sensors, manages the SOS input and buzzer, and communicates with the modem/module over UART. |
| **GNSS + Cellular Connectivity** | **ADIY EC200U Development / Breakout Board** | Provides the planned GNSS/location and cellular communication path. Single unified module (Quectel EC200U). Verify the exact board variant, antenna connectors, power input, UART pins, and modem capabilities from the actual board documentation before wiring. |
| **Motion / Activity Sensing** | **LIS2DU12 Accelerometer Breakout** | Supplies motion samples for activity features. Earlier planning notes mention LIS3DH; the latest wiring-guide artwork labels LIS2DU12. Use the actual purchased breakout and do not silently mix the two part numbers in firmware, diagrams, or the BOM. |
| **Battery Monitoring** | **MAX17048 Fuel-Gauge Breakout** | Estimates Li-Po state of charge / battery level over I²C and monitors the cell through its `BAT/CELL` connection to the Li-Po battery positive node. |
| **Battery** | **Single-cell 3.7 V Nominal Li-Po (1S), Protected / High-Discharge** | Powers the prototype. The saved wiring artwork has inconsistent capacity examples (700 mAh and 1000 mAh). Do not claim either capacity is finalized until the actual selected battery/BOM is confirmed. |
| **Battery Protection** | **1S Li-Po Protection Board (Planned 5A Class)** | Protects the cell/system against over-discharge (<2.8V) and over-current (>5A). Verify its ratings and wiring against its datasheet. **It is not automatically a charger.** |
| **SOS Input** | **Momentary Pushbutton, Active-LOW** | User-triggered emergency/SOS input connected to GPIO with internal pull-up. Released = HIGH, Pressed = LOW. |
| **Audible Alert** | **Piezo Buzzer + NPN Transistor Driver** | Transistor-switched driver (e.g., 2N2222 / PN2222A or equivalent, with ~1 kΩ base resistor). Allows the controller to switch the buzzer without driving it directly from a GPIO pin. |
| **Modem Power Control** | **SPST Slide Switch in the EC200U Power Path** | Enables/disables the EC200U power path separately as shown in the wiring plan. Confirm the switch current rating is adequate. |

### Do Not Substitute These Generic Alternatives
- Do not replace the planned design with an unspecified ESP32 board, generic GPS module, generic GSM module, arbitrary IMU, or optional heart-rate/temperature/SpO₂ sensors.
- Do not add physiological sensors that are not in this hardware specification.
- If the actual EC200U board variant or sensor breakout differs, first compare its real labels and datasheet with this plan and flag any necessary changes.

---

## 2. System Purpose and Expected Device Behavior

The planned collar is intended to supply real device data to PetConnect AI, not to perform medical diagnosis.

### Expected Hardware Functions (After Implementation and Testing):
1. Obtain GNSS/location data through the ADIY EC200U board when a valid fix is available.
2. Read motion/acceleration data from the LIS2DU12 breakout.
3. Read battery/fuel-gauge information from MAX17048.
4. Detect a physical SOS button press.
5. Drive a piezo buzzer through an NPN transistor circuit when firmware requests an audible alert.
6. Use the XIAO ESP32-C6 to coordinate sensors and the cellular/GNSS board.
7. Send telemetry to the backend over the selected and tested cellular/network path.
8. Report device status, validity, and timestamps so the app can distinguish recent data from stale/offline data.

*These are planned capabilities. Do not describe them as working until the hardware is built and the relevant tests pass.*

### Not in This Frozen Hardware Specification
- ❌ Heart-rate sensor.
- ❌ SpO₂ sensor.
- ❌ Core-body-temperature sensor.
- ❌ Camera or microphone.
- ❌ RGB status LED.
- ❌ A second GPS module separate from the EC200U board.
- ❌ A different microcontroller or alternative modem.
- ❌ Any claim that the collar diagnoses illness.

---

## 3. Frozen GPIO and Bus Mapping

Use this mapping as the baseline from the saved PetConnect AI wiring guide:

| XIAO Pin | MCU GPIO | Assigned Function | Notes |
| :---: | :---: | :--- | :--- |
| **D2** | **GPIO2** | **SOS Pushbutton** | Active LOW; button connects GPIO2 to GND when pressed; use pull-up. |
| **D3** | **GPIO21** | **Buzzer Driver** | Active HIGH; control GPIO controls NPN transistor base through ~1 kΩ resistor. |
| **D4** | **GPIO22** | **I²C SDA** | Shared I²C data line for LIS2DU12 and MAX17048. |
| **D5** | **GPIO23** | **I²C SCL** | Shared I²C clock line for LIS2DU12 and MAX17048. |
| **D6** | **GPIO16** | **UART TX from XIAO** | Connect to EC200U UART RX, after confirming voltage levels. |
| **D7** | **GPIO17** | **UART RX to XIAO** | Connect from EC200U UART TX, after confirming voltage levels. |
| **D8** | **GPIO19** | **Reserved** | Do not assign without reviewing the pin plan. |
| **D9** | **GPIO20** | **Reserved** | Do not assign without reviewing the pin plan. |

### UART Crossing
- `XIAO D6 / GPIO16 TX` ──▶ `EC200U UART RX`
- `EC200U UART TX` ──▶ `XIAO D7 / GPIO17 RX`
- Connect grounds together.
- Verify EC200U UART logic levels before direct connection. Use proper level shifting if required by the exact board.

---

## 4. I²C Sensor Connections

The saved final wiring guide labels the accelerometer **LIS2DU12**. The **MAX17048** shares the same I²C bus.

### LIS2DU12 Breakout
- `VDD` ──▶ XIAO 3.3 V
- `VDD_IO` ──▶ XIAO 3.3 V (if that pin exists on the selected breakout and its datasheet specifies this connection)
- `GND` ──▶ Common GND
- `SDA` ──▶ XIAO D4 / GPIO22
- `SCL` ──▶ XIAO D5 / GPIO23
- `INT` ──▶ Optional / unconnected in the baseline wiring unless a later approved design needs it

### MAX17048 Breakout
- `VCC` ──▶ XIAO 3.3 V (according to the selected breakout's requirements)
- `GND` ──▶ Common GND
- `SDA` ──▶ XIAO D4 / GPIO22
- `SCL` ──▶ XIAO D5 / GPIO23
- `BAT/CELL` ──▶ Actual Li-Po battery positive node
- **Critical:** MAX17048 `BAT/CELL` must **not** be connected to the XIAO 3.3 V rail as a substitute for the battery connection.

---

## 5. SOS Button
- **Baseline Circuit:** One side of momentary pushbutton ──▶ XIAO D2 / GPIO2; other side ──▶ Common GND.
- Internal pull-up configured on GPIO2. Released = HIGH, Pressed = LOW.
- **Firmware Requirements:** Debounce the input, recognize deliberate presses reliably, avoid repeatedly flooding messages while held down.

---

## 6. Buzzer and Transistor Driver
- **Baseline Circuit:** XIAO D3 / GPIO21 ──▶ ~1 kΩ base resistor ──▶ NPN transistor base (2N2222 / PN2222A).
- NPN emitter ──▶ Common GND.
- NPN collector ──▶ Buzzer negative terminal.
- Buzzer positive terminal ──▶ Verified positive supply for the actual buzzer.
- **Critical:** Never power the buzzer directly from an ESP32 GPIO.

---

## 7. Battery and Power Architecture

- **Battery Positive is Routed to:**
  1. XIAO BAT+ input as supported by the selected board revision.
  2. MAX17048 `BAT/CELL` measurement node.
  3. SPST switch ──▶ EC200U VBAT power input.
- **Battery Negative & System Grounds are Common.**
- **Dedicated High-Current Modem Rail:** The EC200U has transmit current peaks up to ~2.0 A. **Never** power it from the XIAO 3.3 V output.
- **Battery Capacity Discrepancy:** Saved drawings mention both 700 mAh and 1000 mAh. Capacity is kept as a pending BOM confirmation until the actual cell is physically verified.

---

## 8. Proposed Telemetry Contract

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

## 9. Items Flagged for Final BOM Confirmation
1. Exact ADIY EC200U breakout-board revision and its pinout.
2. Exact LIS2DU12 breakout board and pin labels (reconciled from earlier LIS3DH notes).
3. Actual Li-Po part number, capacity, and dimensions (700 mAh vs 1000 mAh pending).
4. Exact 1S protection board and whether charging is handled off-collar or on-collar.
5. Exact buzzer voltage/current and transistor pinout (E-B-C vs C-B-E).
