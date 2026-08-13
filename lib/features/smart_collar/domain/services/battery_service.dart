/// Battery operating state based on fuel-gauge SoC reading.
enum BatteryState { normal, low, critical, charging, discharging }

/// Hardware-independent abstraction for Smart Collar battery telemetry.
///
/// Wraps fuel-gauge IC communications (e.g. MAX17048/MAX17049 or TI BQ-series)
/// on physical hardware, or provides simulated SoC telemetry when running in software.
abstract class BatteryService {
  /// Returns actual State of Charge (SoC) percentage (0 - 100%) from fuel gauge IC.
  Future<int> getBatteryPercentage();

  /// Returns raw battery voltage in Volts (mV / 1000.0).
  Future<double?> getVoltage();

  /// Indicates if battery charger IC is actively charging the cell.
  Future<bool> isCharging();

  /// Evaluates current battery state (normal, low <=20%, critical <=10%, charging).
  Future<BatteryState> getBatteryStatus();
}

/// Default software implementation simulating / wrapping fuel-gauge readings.
class SimulatedBatteryService implements BatteryService {
  const SimulatedBatteryService({
    this.initialPercentage = 100,
    this.initialVoltage = 4.2,
    this.initialIsCharging = false,
  });

  final int initialPercentage;
  final double initialVoltage;
  final bool initialIsCharging;

  @override
  Future<int> getBatteryPercentage() async => initialPercentage;

  @override
  Future<double?> getVoltage() async => initialVoltage;

  @override
  Future<bool> isCharging() async => initialIsCharging;

  @override
  Future<BatteryState> getBatteryStatus() async {
    if (initialIsCharging) return BatteryState.charging;
    if (initialPercentage <= 10) return BatteryState.critical;
    if (initialPercentage <= 20) return BatteryState.low;
    return BatteryState.discharging;
  }
}
