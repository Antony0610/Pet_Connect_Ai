# Phase 10 — Smart Collar + BLE / GPS / GSM-LTE / Telemetry & Geofencing

## 1. Overview
Phase 10 implements the backend architecture and Clean Architecture integration for physical Smart Collars on the PetConnect AI platform.

The architecture supports multi-modal connectivity (BLE, Wi-Fi, GSM/LTE cellular data transport), MQTT over TLS telemetry ingestion, offline telemetry queueing with original timestamp preservation, Lost Mode state enforcement, and safety geofence zone management.

---

## 2. Database Schema

### Physical Tables
1. `public.smart_collars`: Device registry (`device_id`, `pet_id`, `owner_id`, `firmware_version`, `battery_percentage`, `connectivity_type`, `is_lost_mode`, `is_active`, `last_seen_at`).
2. `public.collar_gps_locations`: GPS telemetry datapoints (`id`, `collar_id`, `pet_id`, `latitude`, `longitude`, `accuracy`, `speed`, `gps_timestamp`, `server_timestamp`, `is_offline_telemetry`).
3. `public.geofences`: Safety zones (`id`, `pet_id`, `owner_id`, `name`, `center_latitude`, `center_longitude`, `radius_meters`, `is_active`).
4. `public.collar_activity_summaries`: Daily activity stats (`id`, `collar_id`, `pet_id`, `activity_date`, `active_minutes`, `rest_minutes`, `step_count`, `calories_burned`).

### RLS Policies
- `smart_collars`: Owners can SELECT, INSERT, UPDATE own collars (`owner_id = auth.uid()`).
- `collar_gps_locations`: Owners and authorized Rescue Volunteers/Admins can SELECT locations for authorized collars.
- `geofences`: Owners can SELECT, INSERT, UPDATE, DELETE own geofences (`owner_id = auth.uid()`).
- `collar_activity_summaries`: Owners can SELECT activity summaries for own collars.

### Realtime Publication
- Enrolled `public.smart_collars` and `public.collar_gps_locations` into `supabase_realtime`.

---

---

## 4. Fuel-Gauge IC Battery Architecture

### Data Flow Architecture
```
Li-ion/LiPo Battery
     ↓
Fuel Gauge IC (e.g. MAX17048/MAX17049 or TI BQ-series)
     ↓
MCU (I2C/SMBus)
     ↓
BLE / Wi-Fi / GSM-LTE
     ↓
Secure Telemetry Ingestion
     ↓
Supabase smart_collars.battery_percentage (State of Charge %)
```

### Configurable Notification Thresholds
- **Low Battery Warning**: `battery_percentage <= 20%` (State: `BatteryState.low`)
- **Critical Battery Warning**: `battery_percentage <= 10%` (State: `BatteryState.critical`)
- System integrates with Phase 8 `public.user_notifications` and Realtime alerts.

---

## 5. Planned Smart Collar Capabilities & Backend Contracts

### 5.1 GSM/LTE Connectivity Status
- `connectivity_type`: Tracks current active radio transport (`BLE`, `WIFI`, `GSM_LTE`).
- `signal_strength`: 0 - 100% RSSI metric.
- Network / Operator status & SIM state tracked server-side on device heartbeat ingestion.

### 5.2 Offline Telemetry / Store-and-Forward
- When cellular connectivity is lost, MCU buffers telemetry points to non-volatile SPI flash.
- Upon reconnecting, queued points are ingested into `collar_gps_locations` with `is_offline_telemetry = true` while preserving original `gps_timestamp`.

### 5.3 Device Heartbeat & Stale Fix Evaluation
- `smart_collars.last_seen_at` is updated on every valid telemetry packet or heartbeat check.
- `SmartCollarHealthService.isDeviceOffline(lastSeenAt, offlineTimeout: 15m)` evaluates device availability.
- Triggers single `public.user_notifications` alert when a collar transitions to offline state.

### 5.4 Safety Geofence Breach Detection
- `SmartCollarHealthService.checkGeofenceBreach(location, geofence)` checks whether current GPS coordinates fall outside `geofences.radius_meters`.
- Emits real-time notification to pet owner when boundary is breached.

### 5.5 Lost Mode Protocol
- When `is_lost_mode = true`, collar telemetry reporting frequency increases (e.g. 10s intervals vs 5m normal).
- Generates high-priority realtime notifications to owner and authorized rescue volunteers.

### 5.6 Hardware Feature Classification Summary

| Feature | Implementation Status |
| :--- | :--- |
| Database Tables & RLS (`smart_collars`, `collar_gps_locations`, `geofences`, `collar_activity_summaries`) | **LIVE SUPABASE VERIFIED** |
| Realtime GPS Stream Enrollment | **LIVE SUPABASE VERIFIED** |
| Clean Architecture, DTOs & UseCases | **SOFTWARE IMPLEMENTED / TESTED** |
| `BatteryService` & `SmartCollarHealthService` abstractions | **SOFTWARE IMPLEMENTED / TESTED** |
| Unit Test Suite (159 tests) | **UNIT TESTED / SIMULATED** |
| Physical Hardware (GPS IC, BLE stack, GSM/eSIM modem, SPI flash) | **REQUIRES PHYSICAL HARDWARE** |

### 5.7 Frontend Integration Summary

- `SmartCollarDashboardScreen`: LIVE (Connected to `registeredCollarsProvider`)
- `SmartCollarGeofenceScreen`: LIVE (Connected to `geofencesProvider`)
- `SmartCollarTrackingScreen`: LIVE (Connected to `registeredCollarsProvider` & `liveGpsLocationStreamProvider`)
- `SmartCollarActivityScreen`: LIVE (Connected to `collarActivitySummariesProvider`)
- `SmartCollarDiagnosticsScreen`: SOFTWARE READY / HARDWARE REQUIRED (Connected to `batteryServiceProvider` & `smartCollarHealthServiceProvider`)
- `SmartCollarSettingsScreen`: LIVE (Connected to `registeredCollarsProvider` & `smartCollarRepositoryProvider`)

---

## 6. Verification Results
- **Unit Tests**: 159/159 unit tests passing (`flutter test test/unit/`).
- **Static Analysis**: `flutter analyze --no-fatal-infos` passed cleanly (0 errors, 0 warnings).
- **Git Sync**: Synced to `origin/master`.
