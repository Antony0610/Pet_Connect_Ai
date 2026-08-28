import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Locale / Language Provider (English & Malayalam)
// ─────────────────────────────────────────────────────────────────────────────

enum AppLanguage {
  english('en', 'English', 'English (US)'),
  malayalam('ml', 'മലയാളം', 'Malayalam (മലയാളം)');

  const AppLanguage(this.code, this.name, this.nativeLabel);
  final String code;
  final String name;
  final String nativeLabel;
}

class LocaleNotifier extends Notifier<Locale> {
  static const _prefKey = 'app_language_code';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_prefKey);
    if (saved == 'ml') return const Locale('ml');
    return const Locale('en');
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = Locale(language.code);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefKey, language.code);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// 2. Theme Mode Provider (Light, Dark, System)
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'app_theme_mode_setting';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_prefKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    final val = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKey, val);
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// 3. Accent Color Palette Provider
// ─────────────────────────────────────────────────────────────────────────────

enum AppAccentPalette {
  teal('Teal Signature', Color(0xFF007A87), Color(0xFFE0F7F6)),
  sapphire('Sapphire Ocean', Color(0xFF2563EB), Color(0xFFDBEAFE)),
  emerald('Emerald Forest', Color(0xFF059669), Color(0xFFD1FAE5)),
  violet('Amethyst Violet', Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  amber('Sunset Amber', Color(0xFFD97706), Color(0xFFFEF3C7)),
  coral('Coral Rose', Color(0xFFE11D48), Color(0xFFFFE4E6));

  const AppAccentPalette(this.label, this.primary, this.container);
  final String label;
  final Color primary;
  final Color container;
}

class AccentColorNotifier extends Notifier<AppAccentPalette> {
  static const _prefKey = 'app_accent_color_index';

  @override
  AppAccentPalette build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final idx = prefs.getInt(_prefKey);
    if (idx != null && idx >= 0 && idx < AppAccentPalette.values.length) {
      return AppAccentPalette.values[idx];
    }
    return AppAccentPalette.teal;
  }

  Future<void> setPalette(AppAccentPalette palette) async {
    state = palette;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_prefKey, palette.index);
  }
}

final accentPaletteProvider = NotifierProvider<AccentColorNotifier, AppAccentPalette>(
  AccentColorNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// 4. Measurement Units
// ─────────────────────────────────────────────────────────────────────────────

enum WeightUnit { kg, lbs }
enum TemperatureUnit { celsius, fahrenheit }
enum DistanceUnit { km, miles }

class MeasurementUnits {
  const MeasurementUnits({
    this.weight = WeightUnit.kg,
    this.temperature = TemperatureUnit.celsius,
    this.distance = DistanceUnit.km,
  });

  final WeightUnit weight;
  final TemperatureUnit temperature;
  final DistanceUnit distance;

  MeasurementUnits copyWith({
    WeightUnit? weight,
    TemperatureUnit? temperature,
    DistanceUnit? distance,
  }) {
    return MeasurementUnits(
      weight: weight ?? this.weight,
      temperature: temperature ?? this.temperature,
      distance: distance ?? this.distance,
    );
  }
}

class MeasurementUnitsNotifier extends Notifier<MeasurementUnits> {
  static const _wKey = 'app_units_weight';
  static const _tKey = 'app_units_temperature';
  static const _dKey = 'app_units_distance';

  @override
  MeasurementUnits build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final w = prefs.getString(_wKey) == 'lbs' ? WeightUnit.lbs : WeightUnit.kg;
    final t = prefs.getString(_tKey) == 'f' ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;
    final d = prefs.getString(_dKey) == 'miles' ? DistanceUnit.miles : DistanceUnit.km;
    return MeasurementUnits(weight: w, temperature: t, distance: d);
  }

  Future<void> setWeight(WeightUnit unit) async {
    state = state.copyWith(weight: unit);
    await ref.read(sharedPreferencesProvider).setString(_wKey, unit.name);
  }

  Future<void> setTemperature(TemperatureUnit unit) async {
    state = state.copyWith(temperature: unit);
    await ref.read(sharedPreferencesProvider).setString(_tKey, unit == TemperatureUnit.fahrenheit ? 'f' : 'c');
  }

  Future<void> setDistance(DistanceUnit unit) async {
    state = state.copyWith(distance: unit);
    await ref.read(sharedPreferencesProvider).setString(_dKey, unit.name);
  }
}

final measurementUnitsProvider = NotifierProvider<MeasurementUnitsNotifier, MeasurementUnits>(
  MeasurementUnitsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// 5. App Notification Settings
// ─────────────────────────────────────────────────────────────────────────────

class AppNotificationSettings {
  const AppNotificationSettings({
    this.healthAlerts = true,
    this.smartCollarAlerts = true,
    this.medicationReminders = true,
    this.communityActivity = true,
    this.dailyDigest = false,
  });

  final bool healthAlerts;
  final bool smartCollarAlerts;
  final bool medicationReminders;
  final bool communityActivity;
  final bool dailyDigest;

  AppNotificationSettings copyWith({
    bool? healthAlerts,
    bool? smartCollarAlerts,
    bool? medicationReminders,
    bool? communityActivity,
    bool? dailyDigest,
  }) {
    return AppNotificationSettings(
      healthAlerts: healthAlerts ?? this.healthAlerts,
      smartCollarAlerts: smartCollarAlerts ?? this.smartCollarAlerts,
      medicationReminders: medicationReminders ?? this.medicationReminders,
      communityActivity: communityActivity ?? this.communityActivity,
      dailyDigest: dailyDigest ?? this.dailyDigest,
    );
  }
}

class AppNotificationSettingsNotifier extends Notifier<AppNotificationSettings> {
  static const _hKey = 'notif_health_alerts';
  static const _cKey = 'notif_collar_alerts';
  static const _mKey = 'notif_med_reminders';
  static const _comKey = 'notif_community_activity';
  static const _dKey = 'notif_daily_digest';

  @override
  AppNotificationSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppNotificationSettings(
      healthAlerts: prefs.getBool(_hKey) ?? true,
      smartCollarAlerts: prefs.getBool(_cKey) ?? true,
      medicationReminders: prefs.getBool(_mKey) ?? true,
      communityActivity: prefs.getBool(_comKey) ?? true,
      dailyDigest: prefs.getBool(_dKey) ?? false,
    );
  }

  Future<void> toggleHealth(bool v) async {
    state = state.copyWith(healthAlerts: v);
    await ref.read(sharedPreferencesProvider).setBool(_hKey, v);
  }

  Future<void> toggleCollar(bool v) async {
    state = state.copyWith(smartCollarAlerts: v);
    await ref.read(sharedPreferencesProvider).setBool(_cKey, v);
  }

  Future<void> toggleMeds(bool v) async {
    state = state.copyWith(medicationReminders: v);
    await ref.read(sharedPreferencesProvider).setBool(_mKey, v);
  }

  Future<void> toggleCommunity(bool v) async {
    state = state.copyWith(communityActivity: v);
    await ref.read(sharedPreferencesProvider).setBool(_comKey, v);
  }

  Future<void> toggleDailyDigest(bool v) async {
    state = state.copyWith(dailyDigest: v);
    await ref.read(sharedPreferencesProvider).setBool(_dKey, v);
  }
}

final appNotificationSettingsProvider =
    NotifierProvider<AppNotificationSettingsNotifier, AppNotificationSettings>(
  AppNotificationSettingsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// 6. Smart Collar Safe Perimeter Zones Persistence
// ─────────────────────────────────────────────────────────────────────────────

class SafeZoneData {
  const SafeZoneData({
    required this.id,
    required this.name,
    required this.radiusMeters,
    this.iconCode = 0xe318, // Icons.home_rounded default
    this.isActive = true,
  });

  final String id;
  final String name;
  final int radiusMeters;
  final int iconCode;
  final bool isActive;

  SafeZoneData copyWith({
    String? name,
    int? radiusMeters,
    int? iconCode,
    bool? isActive,
  }) {
    return SafeZoneData(
      id: id,
      name: name ?? this.name,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      iconCode: iconCode ?? this.iconCode,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'radiusMeters': radiusMeters,
        'iconCode': iconCode,
        'isActive': isActive,
      };

  factory SafeZoneData.fromJson(Map<String, dynamic> json) => SafeZoneData(
        id: json['id'] as String,
        name: json['name'] as String,
        radiusMeters: (json['radiusMeters'] as num?)?.toInt() ?? 150,
        iconCode: (json['iconCode'] as num?)?.toInt() ?? 0xe318,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class SafeZonesNotifier extends Notifier<List<SafeZoneData>> {
  static const _prefKey = 'app_collar_safe_zones_list';

  @override
  List<SafeZoneData> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_prefKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((j) => SafeZoneData.fromJson(j as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [
      SafeZoneData(id: 'z1', name: 'Home Perimeter', radiusMeters: 150, iconCode: 0xe318, isActive: true),
      SafeZoneData(id: 'z2', name: 'Neighborhood Park', radiusMeters: 300, iconCode: 0xe47d, isActive: true),
    ];
  }

  Future<void> _persist(List<SafeZoneData> list) async {
    state = list;
    final encoded = jsonEncode(list.map((z) => z.toJson()).toList());
    await ref.read(sharedPreferencesProvider).setString(_prefKey, encoded);
  }

  Future<void> addZone(SafeZoneData zone) async {
    final updated = [...state, zone];
    await _persist(updated);
  }

  Future<void> updateZone(SafeZoneData zone) async {
    final updated = state.map((z) => z.id == zone.id ? zone : z).toList();
    await _persist(updated);
  }

  Future<void> deleteZone(String id) async {
    final updated = state.where((z) => z.id != id).toList();
    await _persist(updated);
  }
}

final safeZonesProvider = NotifierProvider<SafeZonesNotifier, List<SafeZoneData>>(
  SafeZonesNotifier.new,
);
