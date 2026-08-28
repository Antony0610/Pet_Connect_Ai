import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/smart_collar/domain/services/smart_collar_ble_manager.dart';

void main() {
  group('SmartCollarBleManager Unit Tests', () {
    test('rssiToDistanceMeters computes reasonable proximity distance', () {
      // Calibrated baseline: -59 dBm is ~1.0m
      final dist1m = SmartCollarBleManager.rssiToDistanceMeters(-59);
      expect(dist1m, closeTo(1.0, 0.05));

      // Stronger signal (-50 dBm) should be < 1.0m
      final distClose = SmartCollarBleManager.rssiToDistanceMeters(-50);
      expect(distClose, lessThan(1.0));

      // Weaker signal (-80 dBm) should be > 1.0m
      final distFar = SmartCollarBleManager.rssiToDistanceMeters(-80);
      expect(distFar, greaterThan(3.0));
    });

    test('rssiToQualityPercent maps accurately to 0-100 scale', () {
      expect(SmartCollarBleManager.rssiToQualityPercent(-50), equals(100));
      expect(SmartCollarBleManager.rssiToQualityPercent(-100), equals(0));
      expect(SmartCollarBleManager.rssiToQualityPercent(-75), equals(50));
    });

    test('classifySignal assigns correct quality tiers', () {
      expect(
        SmartCollarBleManager.classifySignal(-55),
        equals(BleSignalQuality.excellent),
      );
      expect(
        SmartCollarBleManager.classifySignal(-70),
        equals(BleSignalQuality.good),
      );
      expect(
        SmartCollarBleManager.classifySignal(-80),
        equals(BleSignalQuality.fair),
      );
      expect(
        SmartCollarBleManager.classifySignal(-90),
        equals(BleSignalQuality.weak),
      );
      expect(
        SmartCollarBleManager.classifySignal(-105),
        equals(BleSignalQuality.outOfRange),
      );
    });

    test('estimateBatteryDays scales appropriately across telemetry intervals', () {
      const fullBattery = 100;

      final emergencyDays = SmartCollarBleManager.estimateBatteryDays(
        batteryPercent: fullBattery,
        pingInterval: const Duration(seconds: 30),
      );
      expect(emergencyDays, equals(2.0));

      final balancedDays = SmartCollarBleManager.estimateBatteryDays(
        batteryPercent: fullBattery,
        pingInterval: const Duration(minutes: 5),
      );
      expect(balancedDays, equals(7.0));

      final powerSaverDays = SmartCollarBleManager.estimateBatteryDays(
        batteryPercent: fullBattery,
        pingInterval: const Duration(minutes: 30),
      );
      expect(powerSaverDays, equals(21.0));
    });
  });
}
