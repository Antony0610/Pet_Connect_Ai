# Smart Collar Architecture

## Overview

PetConnect integrates with ESP32-based smart collars to provide real-time GPS tracking, activity monitoring, geofencing, and emergency features. The system uses WiFi as the primary data path with BLE for initial setup and pairing.

## Connectivity Model

### WiFi (Primary Data Path)
- **Purpose**: Continuous telemetry streaming to cloud
- **Protocol**: HTTPS to Supabase Edge Functions
- **Frequency**: Configurable (default: 30-second intervals for GPS, 5-minute intervals for activity)
- **Advantages**: Higher bandwidth, longer range, lower collar battery impact than constant BLE

### Bluetooth Low Energy (Setup & Pairing)
- **Purpose**: Initial provisioning, WiFi credential transfer, firmware updates
- **Protocol**: BLE GATT services
- **Flow**: App discovers collar → BLE pairing → Transfer WiFi credentials → Collar switches to WiFi
- **Fallback**: Used when WiFi unavailable (e.g., pet indoors without network)

### Connectivity Diagram
```
┌─────────────────┐
│   ESP32 Collar  │
│   - GPS Module  │
│   - WiFi/BLE    │
│   - Accel/Gyro  │
└────────┬────────┘
         │
         ├─[BLE]──────────────┐
         │                    │
         ├─[WiFi]─────────────┼─────→ Internet
         │                    │
         ↓                    ↓
    ┌────────────┐      ┌──────────┐
    │ Flutter App│      │ Supabase │
    │   (Direct  │      │   Edge   │
    │   Pairing) │      │ Functions│
    └────────────┘      └─────┬────┘
                              │
                              ↓
                        ┌──────────────┐
                        │   Postgres   │
                        │  + Realtime  │
                        └──────────────┘
                              │
                              ↓
                        ┌──────────────┐
                        │ Flutter App  │
                        │ (Realtime    │
                        │  Updates)    │
                        └──────────────┘
```

## Pairing Flow

### Initial Setup
1. **Discovery**: User taps "Add Smart Collar" in app
2. **BLE Scan**: App scans for nearby collars advertising `PETCONNECT_COLLAR` service
3. **Selection**: User selects collar from list (matched by serial number)
4. **Pairing**: BLE pairing initiated with PIN shown on packaging
5. **Provisioning**: App sends WiFi SSID/password + device auth token via BLE
6. **Activation**: Collar connects to WiFi, registers with backend, switches to WiFi mode
7. **Confirmation**: App receives confirmation via Supabase Realtime

### BLE GATT Services
```
Service UUID: 0000FFF0-0000-1000-8000-00805F9B34FB

Characteristics:
- WiFi SSID (Write): 0000FFF1-...
- WiFi Password (Write): 0000FFF2-...
- Device Token (Write): 0000FFF3-...
- Status (Read/Notify): 0000FFF4-...
- Battery Level (Read): 0000FFF5-...
```

## Data Model

### Telemetry Schema
```dart
class CollarTelemetry {
  final String collarId;
  final DateTime timestamp;
  final GpsData gps;
  final ActivityData activity;
  final BatteryData battery;
  final DeviceHealth deviceHealth;
  
  CollarTelemetry({
    required this.collarId,
    required this.timestamp,
    required this.gps,
    required this.activity,
    required this.battery,
    required this.deviceHealth,
  });
}

class GpsData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;  // meters
  final double heading;   // degrees
  final double speed;     // m/s
}

class ActivityData {
  final int steps;
  final double distance;  // meters
  final int activeMinutes;
  final int restMinutes;
  final ActivityLevel level;  // RESTING, WALKING, RUNNING, PLAYING
}

class BatteryData {
  final int percentage;
  final bool isCharging;
  final int estimatedHoursRemaining;
}

class DeviceHealth {
  final double temperature;  // Celsius
  final int signalStrength;  // dBm
  final String firmwareVersion;
  final DateTime lastSync;
}
```

### Database Schema
```sql
CREATE TABLE collar_telemetry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collar_id UUID NOT NULL REFERENCES collars(id),
  pet_id UUID NOT NULL REFERENCES pets(id),
  timestamp TIMESTAMPTZ NOT NULL,
  gps JSONB NOT NULL,
  activity JSONB NOT NULL,
  battery JSONB NOT NULL,
  device_health JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX ON collar_telemetry (collar_id, timestamp DESC);
CREATE INDEX ON collar_telemetry USING GIST (
  (gps->>'latitude')::FLOAT8,
  (gps->>'longitude')::FLOAT8
);

-- Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE collar_telemetry;
```

## Data Transport

### Collar → Cloud (WiFi)
ESP32 firmware sends HTTPS POST to Supabase Edge Function:

```typescript
// supabase/functions/collar-ingest/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  // 1. Verify device auth token
  const authToken = req.headers.get('X-Device-Token');
  const { collarId } = await verifyDeviceToken(authToken);
  
  // 2. Parse telemetry payload
  const telemetry = await req.json();
  
  // 3. Insert to Postgres (triggers Realtime broadcast)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  const { data, error } = await supabase
    .from('collar_telemetry')
    .insert({
      collar_id: collarId,
      pet_id: telemetry.petId,
      timestamp: telemetry.timestamp,
      gps: telemetry.gps,
      activity: telemetry.activity,
      battery: telemetry.battery,
      device_health: telemetry.deviceHealth,
    })
    .select()
    .single();
  
  // 4. Check geofence violations (async)
  await checkGeofences(data);
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

### Cloud → App (Realtime)
Flutter app subscribes to collar_telemetry changes:

```dart
class RealtimeCollarService {
  final SupabaseClient _client;
  
  Stream<CollarTelemetry> watchCollar(String collarId) {
    return _client
        .from('collar_telemetry')
        .stream(primaryKey: ['id'])
        .eq('collar_id', collarId)
        .map((records) => records.map(CollarTelemetry.fromJson).toList())
        .expand((list) => list);
  }
}
```

## Geofence & Safe Zones

### Zone Definition
```dart
class SafeZone {
  final String id;
  final String name;
  final LatLng center;
  final double radius;  // meters
  final bool alertOnExit;
  final bool alertOnEntry;
  final List<String> notifyUsers;  // user IDs
}
```

### Server-Side Evaluation
Geofence checks happen in Edge Function to avoid client-side delays:

```typescript
async function checkGeofences(telemetry: CollarTelemetry) {
  const { data: zones } = await supabase
    .from('safe_zones')
    .select('*')
    .eq('pet_id', telemetry.pet_id)
    .eq('active', true);
  
  for (const zone of zones) {
    const distance = calculateDistance(
      telemetry.gps.latitude,
      telemetry.gps.longitude,
      zone.center_lat,
      zone.center_lng
    );
    
    const isInside = distance <= zone.radius;
    const wasInside = await checkPreviousState(telemetry.collar_id, zone.id);
    
    // Trigger alert on boundary crossing
    if (zone.alert_on_exit && wasInside && !isInside) {
      await sendGeofenceAlert('exit', telemetry, zone);
    }
    if (zone.alert_on_entry && !wasInside && isInside) {
      await sendGeofenceAlert('entry', telemetry, zone);
    }
    
    // Update state
    await updateZoneState(telemetry.collar_id, zone.id, isInside);
  }
}
```

### Push Notifications
On breach, n8n workflow triggers FCM push:
- "⚠️ Max left the safe zone 'Backyard' at 2:45 PM"
- Includes map snapshot and "Track Now" deep link

## Lost Mode

### Emergency Broadcast
When owner activates Lost Mode:
1. **Collar Settings Update**: Increased GPS frequency (every 10 seconds)
2. **Community Alert**: Broadcast to nearby PetConnect users
3. **Public Profile**: Temporary public page with contact info
4. **Audible Alarm**: Collar emits sound if found (optional)

### Community Sighting Flow
```
User A enables Lost Mode for "Max"
    ↓
Broadcast created in database
    ↓
Nearby users (within 10km) receive push notification
    ↓
User B spots Max, taps "Report Sighting"
    ↓
User B's location + photo sent to User A
    ↓
User A receives real-time notification with map
```

### Lost Mode Telemetry
```sql
CREATE TABLE lost_pet_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES pets(id),
  activated_at TIMESTAMPTZ NOT NULL,
  last_known_location GEOGRAPHY(POINT) NOT NULL,
  contact_phone TEXT,
  reward_amount DECIMAL(10, 2),
  status TEXT DEFAULT 'active',  -- 'active', 'found', 'cancelled'
  CONSTRAINT lost_pet_broadcasts_status_check CHECK (status IN ('active', 'found', 'cancelled'))
);

CREATE INDEX ON lost_pet_broadcasts USING GIST (last_known_location);
```

## Battery & Device Health

### Battery Optimization
- **Normal Mode**: GPS every 30s, WiFi sync every 5min → ~5 days battery
- **Power Save Mode**: GPS every 5min, WiFi sync every 30min → ~14 days battery
- **Lost Mode**: GPS every 10s, WiFi sync every 30s → ~12 hours battery

### Low Battery Alerts
```typescript
if (telemetry.battery.percentage < 20 && !telemetry.battery.isCharging) {
  await sendNotification(telemetry.pet.owner_id, {
    title: 'Low Collar Battery',
    body: `${telemetry.pet.name}'s collar battery is at ${telemetry.battery.percentage}%. Please charge soon.`,
    data: { type: 'low_battery', collarId: telemetry.collar_id }
  });
}
```

### Health Monitoring
Track collar issues:
- **Temperature Anomalies**: Alert if >45°C (potential malfunction)
- **GPS Signal Loss**: Alert if no fix for >30 minutes
- **Offline Detection**: Alert if no data received for >2 hours
- **Firmware Updates**: Notify users of available updates

## Offline Buffering

### Local Storage on ESP32
When WiFi unavailable, collar buffers telemetry:
```c
#define MAX_BUFFER_SIZE 1000  // ~8 hours at 30s intervals

struct TelemetryBuffer {
  TelemetryRecord records[MAX_BUFFER_SIZE];
  uint16_t write_index;
  uint16_t read_index;
  bool is_full;
};
```

### Sync on Reconnect
Upon WiFi reconnection:
1. Collar uploads buffered records in batch (max 100 per request)
2. Edge Function processes with `is_backfill=true` flag
3. App UI shows "Syncing historical data..." during upload
4. Gaps in timeline filled retrospectively

## Security

### Device Authentication
Each collar has unique auth token generated during manufacturing:
```sql
CREATE TABLE collars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  serial_number TEXT UNIQUE NOT NULL,
  auth_token TEXT UNIQUE NOT NULL,  -- SHA-256 hashed
  pet_id UUID REFERENCES pets(id),
  owner_id UUID REFERENCES users(id),
  registered_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ
);
```

### Secure Communication
- **HTTPS Only**: All collar→cloud communication over TLS 1.3
- **Token Rotation**: Auth tokens rotated every 90 days
- **Rate Limiting**: Max 120 requests/hour per collar (prevents abuse)
- **Replay Protection**: Timestamp validation (reject if >5 minutes old)

### Firmware Security
- **Signed Updates**: OTA updates verified with RSA-2048 signature
- **Secure Boot**: ESP32 secure boot enabled to prevent firmware tampering
- **Debug Disable**: JTAG disabled in production firmware

## App-Side Service Interface

### smart_collar_service.dart Sketch
```dart
abstract class SmartCollarService {
  /// Scan for nearby collars via BLE
  Stream<DiscoveredCollar> scanForCollars();
  
  /// Pair and provision a new collar
  Future<Collar> pairCollar({
    required String serialNumber,
    required String wifiSsid,
    required String wifiPassword,
  });
  
  /// Watch real-time telemetry for a collar
  Stream<CollarTelemetry> watchTelemetry(String collarId);
  
  /// Get historical telemetry
  Future<List<CollarTelemetry>> getHistory({
    required String collarId,
    required DateTimeRange range,
  });
  
  /// Manage safe zones
  Future<SafeZone> createSafeZone({
    required String petId,
    required String name,
    required LatLng center,
    required double radius,
  });
  
  /// Activate/deactivate lost mode
  Future<void> setLostMode({
    required String collarId,
    required bool enabled,
    String? contactPhone,
    double? rewardAmount,
  });
  
  /// Update collar settings
  Future<void> updateSettings({
    required String collarId,
    required CollarSettings settings,
  });
  
  /// Check firmware updates
  Future<FirmwareUpdate?> checkForUpdates(String collarId);
  
  /// Initiate firmware update via BLE
  Future<void> updateFirmware({
    required String collarId,
    required FirmwareUpdate update,
  });
}

class SupabaseSmartCollarService implements SmartCollarService {
  final SupabaseClient _client;
  final FlutterBluePlus _bluetooth;
  
  @override
  Stream<CollarTelemetry> watchTelemetry(String collarId) {
    return _client
        .from('collar_telemetry')
        .stream(primaryKey: ['id'])
        .eq('collar_id', collarId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((records) => CollarTelemetry.fromJson(records.first));
  }
  
  // ... other implementations
}
```

## UI Integration

### Live GPS Tracking Screen
- **Map View**: Google Maps with pet location marker (updated every 30s via Realtime)
- **Trail History**: Show last 24 hours of movement (polyline)
- **Safe Zones**: Visualize geofences as colored circles
- **Info Panel**: Current speed, heading, last update time

### Geofence Alerts Screen
- **Alert History**: List of all boundary crossings
- **Map Visualization**: Tap alert to see location on map
- **Notification Settings**: Configure which zones trigger alerts

### Device Health Screen
- **Battery Gauge**: Visual indicator with percentage
- **Signal Strength**: WiFi/GPS signal quality
- **Status Indicators**: Online/offline, charging, firmware version
- **Settings**: Power mode, update frequency, lost mode toggle

## Future Enhancements

- **Multi-Pet Tracking**: Display multiple pets on single map
- **Activity Analytics**: Compare pet activity to breed averages
- **Health Correlations**: Link activity drops to health records
- **Predictive Alerts**: "Max is usually more active at this time—check on him?"
- **Voice Commands**: "Find Max" via smart speaker integration
- **LoRa Backup**: Long-range fallback for areas without WiFi/cellular
