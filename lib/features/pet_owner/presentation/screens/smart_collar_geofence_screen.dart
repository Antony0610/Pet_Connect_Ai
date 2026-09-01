import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:latlong2/latlong.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/providers/settings_providers.dart';
import 'package:petconnect_ai/core/services/notification_service.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Safe Zones / Geofencing** — `/owner/collar/geofence`.
///
/// Fully interactive safe zones management:
/// - Real-time radius adjustments (50m - 1000m)
/// - Add, edit, delete, and pause safe perimeter boundaries
/// - Dynamic interactive map circles
/// - Tap to relocate safe perimeter center on OpenStreetMap
/// - Persistent SharedPreferences storage
class SmartCollarGeofenceScreen extends ConsumerStatefulWidget {
  const SmartCollarGeofenceScreen({super.key});

  @override
  ConsumerState<SmartCollarGeofenceScreen> createState() =>
      _SmartCollarGeofenceScreenState();
}

class _SmartCollarGeofenceScreenState
    extends ConsumerState<SmartCollarGeofenceScreen> {
  bool _emergencySirenEnabled = true;
  String? _repositioningZoneId;

  @override
  void initState() {
    super.initState();
    _loadSirenPref();
  }

  void _loadSirenPref() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _emergencySirenEnabled = prefs.getBool('app_collar_siren_enabled') ?? true;
    });
  }

  Future<void> _toggleSiren(bool val) async {
    setState(() => _emergencySirenEnabled = val);
    await ref.read(sharedPreferencesProvider).setBool('app_collar_siren_enabled', val);
  }

  void _openAddZoneDialog() async {
    final nameCtrl = TextEditingController();
    double radiusMeters = 150;
    int selectedIconCode = 0xe318; // Icons.home_rounded

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Safe Perimeter Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Safe Zone Name',
                    hintText: 'e.g. Dog Park, Grandma\'s Yard',
                    prefixIcon: Icon(Icons.shield_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zone Icon',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final icon in [
                      Icons.home_rounded,
                      Icons.park_rounded,
                      Icons.local_hospital_rounded,
                      Icons.pets_rounded,
                      Icons.nature_people_rounded,
                    ])
                      InkWell(
                        onTap: () => setDlgState(() => selectedIconCode = icon.codePoint),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedIconCode == icon.codePoint
                                ? context.colorScheme.primaryContainer
                                : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIconCode == icon.codePoint
                                  ? context.colorScheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selectedIconCode == icon.codePoint
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perimeter Radius:',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${radiusMeters.round()} meters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: radiusMeters,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${radiusMeters.round()}m',
                  onChanged: (val) => setDlgState(() => radiusMeters = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Create Zone'),
            ),
          ],
        ),
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final newZone = SafeZoneData(
        id: 'z_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        radiusMeters: radiusMeters.round(),
        iconCode: selectedIconCode,
        isActive: true,
      );
      await ref.read(safeZonesProvider.notifier).addZone(newZone);
      if (mounted) {
        context.showSnackbar(
          'Safe Zone "${newZone.name}" (${newZone.radiusMeters}m) established!',
        );
      }
    }
  }

  void _openEditZoneDialog(SafeZoneData zone) async {
    final nameCtrl = TextEditingController(text: zone.name);
    double radiusMeters = zone.radiusMeters.toDouble().clamp(50.0, 1000.0);
    int selectedIconCode = zone.iconCode;
    bool isActive = zone.isActive;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Safe Perimeter Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Safe Zone Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zone Icon',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final icon in [
                      Icons.home_rounded,
                      Icons.park_rounded,
                      Icons.local_hospital_rounded,
                      Icons.pets_rounded,
                      Icons.nature_people_rounded,
                    ])
                      InkWell(
                        onTap: () => setDlgState(() => selectedIconCode = icon.codePoint),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedIconCode == icon.codePoint
                                ? context.colorScheme.primaryContainer
                                : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIconCode == icon.codePoint
                                  ? context.colorScheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selectedIconCode == icon.codePoint
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perimeter Radius:',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${radiusMeters.round()} meters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: radiusMeters,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${radiusMeters.round()}m',
                  onChanged: (val) => setDlgState(() => radiusMeters = val),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zone Active', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: isActive,
                  onChanged: (val) => setDlgState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (updated == true && nameCtrl.text.trim().isNotEmpty) {
      final modifiedZone = zone.copyWith(
        name: nameCtrl.text.trim(),
        radiusMeters: radiusMeters.round(),
        iconCode: selectedIconCode,
        isActive: isActive,
      );
      await ref.read(safeZonesProvider.notifier).updateZone(modifiedZone);
      if (mounted) {
        context.showSnackbar(
          'Safe Zone "${modifiedZone.name}" updated to ${modifiedZone.radiusMeters}m radius!',
        );
      }
    }
  }

  void _deleteZone(String id) async {
    await ref.read(safeZonesProvider.notifier).deleteZone(id);
    if (mounted) {
      context.showSnackbar('Safe zone removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;

    final zones = ref.watch(safeZonesProvider);
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';

    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final defaultLat = profile?.latitude ?? 10.2312;
    final defaultLng = profile?.longitude ?? 76.2829;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(
        context,
        title: 'Safe Zones',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            tooltip: 'Add safe zone',
            onPressed: _openAddZoneDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                AppSpacing.md,
                margin,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CollarMapPreview(
                    latitude: defaultLat,
                    longitude: defaultLng,
                    locationLabel: _repositioningZoneId != null
                        ? 'Tap Map to Relocate Center'
                        : '${zones.where((z) => z.isActive).length} Safe Perimeters Active',
                    petName: petName,
                    isEditMode: _repositioningZoneId != null,
                    editModeMessage: _repositioningZoneId != null
                        ? 'Tap on map to relocate "${zones.firstWhere((z) => z.id == _repositioningZoneId, orElse: () => zones.first).name}"'
                        : null,
                    onMapTap: (point) {
                      if (_repositioningZoneId != null) {
                        final movingZone = zones.firstWhere(
                          (z) => z.id == _repositioningZoneId,
                          orElse: () => zones.first,
                        );
                        ref.read(safeZonesProvider.notifier).updateZoneCenter(
                              _repositioningZoneId!,
                              point.latitude,
                              point.longitude,
                            );
                        context.showSnackbar(
                          'Moved "${movingZone.name}" to ${point.latitude.toStringAsFixed(4)}°N, ${point.longitude.abs().toStringAsFixed(4)}°W',
                        );
                        setState(() => _repositioningZoneId = null);
                      }
                    },
                    safeZones: zones.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final zone = entry.value;
                      final offset = idx == 0
                          ? const Offset(0, 0)
                          : Offset((idx * 45.0) - 20, (idx * -35.0) + 15);
                      return MapSafeZone(
                        id: zone.id,
                        name: '${zone.name} (${zone.radiusMeters}m)',
                        radiusMeters: zone.radiusMeters.toDouble(),
                        centerOffset: offset,
                        centerLatLng: (zone.latitude != null && zone.longitude != null)
                            ? LatLng(zone.latitude!, zone.longitude!)
                            : null,
                        color: zone.id == _repositioningZoneId
                            ? scheme.tertiary
                            : (zone.isActive ? AppColors.success : AppColors.info),
                      );
                    }).toList(),
                    height: isWide ? 340 : 260,
                    onTap: () {
                      if (_repositioningZoneId == null) {
                        context.showSnackbar('Live safe boundaries active for $petName');
                      }
                    },
                  ),
                  if (zones.isNotEmpty) ...[
                    AppSpacing.vGapSm,
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                                  AppSpacing.hGapXs,
                                  Text(
                                    'Adjust ${zones.first.name} Perimeter',
                                    style: context.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer,
                                      borderRadius: AppRadius.brPill,
                                    ),
                                    child: Text(
                                      '${zones.first.radiusMeters.round()}m radius',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Slider(
                            value: zones.first.radiusMeters.toDouble().clamp(50.0, 1000.0),
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '${zones.first.radiusMeters}m',
                            onChanged: (val) {
                              final updated = zones.first.copyWith(radiusMeters: val.toInt());
                              ref.read(safeZonesProvider.notifier).updateZone(updated);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 4),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  _repositioningZoneId == zones.first.id
                                      ? Icons.cancel_rounded
                                      : Icons.pin_drop_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  _repositioningZoneId == zones.first.id
                                      ? 'Cancel Relocation'
                                      : 'Relocate Center on Map',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _repositioningZoneId == zones.first.id
                                      ? scheme.error
                                      : scheme.primary,
                                  side: BorderSide(
                                    color: _repositioningZoneId == zones.first.id
                                        ? scheme.error
                                        : scheme.primary,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _repositioningZoneId = _repositioningZoneId == zones.first.id
                                        ? null
                                        : zones.first.id;
                                  });
                                  if (_repositioningZoneId != null) {
                                    context.showSnackbar('Tap anywhere on the map to relocate "${zones.first.name}"');
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  AppSpacing.vGapLg,
                  Row(
                    children: [
                      Text(
                        'Your Safe Zones',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${zones.length} configured',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  if (zones.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: scheme.onSurfaceVariant,
                          ),
                          AppSpacing.vGapSm,
                          Text(
                            'No safe zones configured yet',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Create a safe perimeter to get alerts when $petName leaves home.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.vGapMd,
                          FilledButton.icon(
                            onPressed: _openAddZoneDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Safe Zone'),
                          ),
                        ],
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < zones.length; i++) ...[
                            if (i > 0)
                              Divider(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                                height: AppSpacing.lg,
                              ),
                            _ZoneRow(
                              zone: zones[i],
                              isRelocating: _repositioningZoneId == zones[i].id,
                              onRelocate: () {
                                setState(() {
                                  _repositioningZoneId = _repositioningZoneId == zones[i].id
                                      ? null
                                      : zones[i].id;
                                });
                                if (_repositioningZoneId != null) {
                                  context.showSnackbar('Tap anywhere on the map to relocate "${zones[i].name}"');
                                }
                              },
                              onEdit: () => _openEditZoneDialog(zones[i]),
                              onDelete: () => _deleteZone(zones[i].id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  AppSpacing.vGapMd,
                  AppButton.outlined(
                    label: 'Add Safe Zone',
                    icon: Icons.add_rounded,
                    borderRadius: AppRadius.brPill,
                    onPressed: _openAddZoneDialog,
                  ),
                  AppSpacing.vGapXl,

                  // ── Perimeter Telemetry & Emergency Controls ───
                  Text(
                    'Perimeter Security & Auto-Alerts',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  AppCard(
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          secondary: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: scheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Emergency Siren on Breach',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          subtitle: Text(
                            'Immediately rings collar audio siren and dispatches high-priority push alert.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          value: _emergencySirenEnabled,
                          onChanged: (val) {
                            _toggleSiren(val);
                            context.showSnackbar(
                              val
                                  ? 'Emergency breach siren enabled for $petName.'
                                  : 'Emergency breach siren muted.',
                            );
                          },
                        ),
                        Divider(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                          height: AppSpacing.lg,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: AppRadius.brSm,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Boundary Status: All Clear',
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      fontWeight: AppTypography.semiBold,
                                    ),
                                  ),
                                  Text(
                                    zones.isNotEmpty
                                        ? '$petName is currently inside ${zones.first.name} (${zones.first.radiusMeters}m). 0 breaches logged.'
                                        : '$petName location tracked. 0 breaches logged.',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                            label: const Text('Simulate Boundary Breach Alert'),
                            onPressed: () async {
                              final zoneName = zones.isNotEmpty ? zones.first.name : 'Home Perimeter';
                              await NotificationService.instance.showGeofenceBreachAlarm(
                                petName: petName,
                                zoneName: zoneName,
                              );
                              if (!context.mounted) return;
                              context.showSnackbar('⚠️ Geofence breach alarm notification dispatched!');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

IconData _getSafeZoneIcon(int code) {
  if (code == Icons.home_rounded.codePoint) return Icons.home_rounded;
  if (code == Icons.park_rounded.codePoint) return Icons.park_rounded;
  if (code == Icons.local_hospital_rounded.codePoint) return Icons.local_hospital_rounded;
  if (code == Icons.pets_rounded.codePoint) return Icons.pets_rounded;
  if (code == Icons.nature_people_rounded.codePoint) return Icons.nature_people_rounded;
  if (code == Icons.home.codePoint) return Icons.home;
  if (code == Icons.park.codePoint) return Icons.park;
  return Icons.location_on_rounded;
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zone,
    required this.onEdit,
    required this.onDelete,
    required this.onRelocate,
    this.isRelocating = false,
  });

  final SafeZoneData zone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRelocate;
  final bool isRelocating;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final iconData = _getSafeZoneIcon(zone.iconCode);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isRelocating
                    ? scheme.tertiaryContainer
                    : (zone.isActive ? scheme.primaryContainer : scheme.surfaceContainerHighest),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isRelocating
                    ? scheme.tertiary
                    : (zone.isActive ? scheme.primary : scheme.onSurfaceVariant),
                size: AppIconSizes.md,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          zone.name,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      ),
                      if (isRelocating) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tap Map to Move',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ] else if (!zone.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Paused',
                            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    zone.latitude != null && zone.longitude != null
                        ? '${zone.radiusMeters}m radius • (${zone.latitude!.toStringAsFixed(3)}°, ${zone.longitude!.abs().toStringAsFixed(3)}°)'
                        : '${zone.radiusMeters} m perimeter radius',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isRelocating ? Icons.pin_drop : Icons.pin_drop_outlined,
                size: 20,
                color: isRelocating ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
              tooltip: isRelocating ? 'Cancel Moving' : 'Move Center on Map',
              onPressed: onRelocate,
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: scheme.primary),
              tooltip: 'Adjust Safe Zone',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
              tooltip: 'Delete Zone',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
