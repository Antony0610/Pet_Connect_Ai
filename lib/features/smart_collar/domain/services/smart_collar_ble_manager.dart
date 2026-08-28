import 'dart:math';

/// Signal quality classification for Bluetooth Low Energy smart collar beacons.
enum BleSignalQuality {
  excellent,
  good,
  fair,
  weak,
  outOfRange,
}

/// Helper service for Smart Collar Bluetooth Low Energy (BLE) proximity tracking,
/// RSSI-to-distance conversion, and battery power profile optimization.
class SmartCollarBleManager {
  const SmartCollarBleManager._();

  /// Measured RSSI at 1 meter distance (standard calibrated path-loss baseline for 0dBm BLE beacons).
  static const double _measuredPower1M = -59.0;

  /// Environmental path loss exponent (2.0 = free space, 2.5 - 3.5 = typical indoor/outdoor mix).
  static const double _pathLossExponent = 2.8;

  /// Calculates estimated distance in meters based on the received signal strength indication (RSSI in dBm).
  static double rssiToDistanceMeters(int rssi) {
    if (rssi == 0) return -1.0; // Cannot determine
    final ratio = (_measuredPower1M - rssi) / (10 * _pathLossExponent);
    return pow(10.0, ratio).toDouble();
  }

  /// Converts RSSI (typically -100 dBm to -40 dBm) to a normalized signal quality percentage (0% to 100%).
  static int rssiToQualityPercent(int rssi) {
    if (rssi >= -50) return 100;
    if (rssi <= -100) return 0;
    return (2 * (rssi + 100)).clamp(0, 100);
  }

  /// Categorizes RSSI into discrete signal quality tiers.
  static BleSignalQuality classifySignal(int rssi) {
    if (rssi >= -60) return BleSignalQuality.excellent;
    if (rssi >= -75) return BleSignalQuality.good;
    if (rssi >= -85) return BleSignalQuality.fair;
    if (rssi >= -95) return BleSignalQuality.weak;
    return BleSignalQuality.outOfRange;
  }

  /// Estimates battery life in days based on battery percentage and GPS telemetry interval.
  static double estimateBatteryDays({
    required int batteryPercent,
    required Duration pingInterval,
  }) {
    final seconds = pingInterval.inSeconds;
    // Base max battery life at 100% capacity:
    // 30s ping: ~48 hours (2.0 days)
    // 5m (300s) ping: ~168 hours (7.0 days)
    // 15m (900s) ping: ~336 hours (14.0 days)
    // 30m (1800s) ping: ~504 hours (21.0 days)
    final maxDays = switch (seconds) {
      <= 30 => 2.0,
      <= 300 => 7.0,
      <= 900 => 14.0,
      _ => 21.0,
    };

    return (batteryPercent / 100.0) * maxDays;
  }

  /// Formats BLE beacon status label.
  static String formatBleStatus({
    required int rssi,
    required bool isConnected,
  }) {
    if (!isConnected) return 'Beacon Offline';
    final dist = rssiToDistanceMeters(rssi);
    final percent = rssiToQualityPercent(rssi);
    return '$percent% Signal (~${dist.toStringAsFixed(1)}m proximity)';
  }
}
