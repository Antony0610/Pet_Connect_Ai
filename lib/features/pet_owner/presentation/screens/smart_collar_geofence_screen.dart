import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A defined geofence the collar watches, with its live in/out status.
class _Zone {
  const _Zone(this.id, this.icon, this.name, this.radiusMeters, this.inside);

  final String id;
  final IconData icon;
  final String name;
  final int radiusMeters;
  final bool inside;

  _Zone copyWith({String? name, int? radiusMeters, bool? inside}) {
    return _Zone(
      id,
      icon,
      name ?? this.name,
      radiusMeters ?? this.radiusMeters,
      inside ?? this.inside,
    );
  }
}

/// **Safe Zones / Geofencing** — `/owner/collar/geofence`.
class SmartCollarGeofenceScreen extends ConsumerStatefulWidget {
  const SmartCollarGeofenceScreen({super.key});

  @override
  ConsumerState<SmartCollarGeofenceScreen> createState() =>
      _SmartCollarGeofenceScreenState();
}

class _SmartCollarGeofenceScreenState
    extends ConsumerState<SmartCollarGeofenceScreen> {
  final List<_Zone> _localZones = [
    const _Zone('z1', Icons.home_rounded, 'Home Zone', 150, true),
    const _Zone('z2', Icons.park_rounded, 'Neighborhood Park', 300, true),
  ];

  void _openAddZoneDialog() async {
    final nameCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '200');

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Safe Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                hintText: 'e.g. Grandma\'s House, Dog Park',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                hintText: 'e.g. 150',
                suffixText: 'm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add Zone'),
          ),
        ],
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final rad = int.tryParse(radiusCtrl.text.trim()) ?? 150;
      setState(() {
        _localZones.add(
          _Zone(
            'z_${DateTime.now().millisecondsSinceEpoch}',
            Icons.shield_rounded,
            nameCtrl.text.trim(),
            rad,
            true,
          ),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Safe Zone "${nameCtrl.text.trim()}" added!')),
        );
      }
    }
  }

  void _deleteZone(String id) {
    setState(() {
      _localZones.removeWhere((z) => z.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safe zone removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;

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
                    locationLabel: '${_localZones.length} Safe Perimeters Active',
                    safeZones: _localZones.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final zone = entry.value;
                      final offset = idx == 0
                          ? const Offset(0, 0)
                          : Offset((idx * 45.0) - 20, (idx * -35.0) + 15);
                      return MapSafeZone(
                        id: zone.id,
                        name: '${zone.name} (${zone.radiusMeters}m)',
                        radiusMeters: (zone.radiusMeters * 0.6).clamp(40.0, 160.0),
                        centerOffset: offset,
                        color: zone.inside ? AppColors.success : AppColors.info,
                      );
                    }).toList(),
                    height: isWide ? 340 : 260,
                    onTap: () => context.showSnackbar('Live safe boundaries active'),
                  ),
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
                        '${_localZones.length} configured',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  if (_localZones.isEmpty)
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
                            'Create a safe perimeter to get alerts when your pet leaves home.',
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
                          for (var i = 0; i < _localZones.length; i++) ...[
                            if (i > 0)
                              Divider(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                                height: AppSpacing.lg,
                              ),
                            _ZoneRow(
                              zone: _localZones[i],
                              onDelete: () => _deleteZone(_localZones[i].id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  AppSpacing.vGapLg,
                  AppButton.outlined(
                    label: 'Add Safe Zone',
                    icon: Icons.add_rounded,
                    borderRadius: AppRadius.brPill,
                    onPressed: _openAddZoneDialog,
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

/// One safe-zone row: a tinted glyph, the zone name and radius, and a status
/// pill reading "Inside" (accent) or "Outside" (neutral).
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.onDelete});

  final _Zone zone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    final (pillBg, pillFg) = zone.inside
        ? (
            palette.accentContainer(brightness),
            palette.onAccentContainer(brightness),
          )
        : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            zone.icon,
            color: scheme.onPrimaryContainer,
            size: AppIconSizes.md,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.name,
                style: context.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              AppSpacing.vGapXs,
              Text(
                '${zone.radiusMeters} m radius',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            zone.inside ? 'Inside' : 'Outside',
            style: context.textTheme.labelMedium?.copyWith(
              color: pillFg,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
          tooltip: 'Delete Zone',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
