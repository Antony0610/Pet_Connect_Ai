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

## 5. Verification Results
- **Unit Tests**: 158/158 unit tests passing (`flutter test test/unit/`).
- **Static Analysis**: `flutter analyze --no-fatal-infos` passed cleanly (0 errors, 0 warnings).
- **Git Sync**: Synced to `origin/master`.
