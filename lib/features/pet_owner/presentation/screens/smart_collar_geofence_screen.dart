import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A defined geofence the collar watches, with its live in/out status.
class _Zone {
  const _Zone(this.icon, this.name, this.radius, this.inside);

  final IconData icon;
  final String name;
  final String radius;
  final bool inside;
}

/// **Safe Zones / Geofencing** — `/owner/collar/geofence`.
///
/// A map preview of the active geofences over a list of safe zones, each
/// showing whether Buddy is currently inside, plus an "add zone" action.
/// Composes the frozen collar primitives; token-driven, one tree both themes.
class SmartCollarGeofenceScreen extends ConsumerWidget {
  const SmartCollarGeofenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;
    final geofencesAsync = ref.watch(geofencesProvider);

    const zones = [
      _Zone(Icons.home_rounded, 'Home', '120 m radius', true),
      _Zone(Icons.park_rounded, 'Centennial Park', '250 m radius', true),
      _Zone(
        Icons.local_hospital_rounded,
        "Dr. Miller's Vet",
        '80 m radius',
        false,
      ),
      _Zone(Icons.storefront_rounded, 'Pet Supplies Co.', '60 m radius', false),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(
        context,
        title: 'Safe Zones',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            tooltip: 'Add safe zone',
            onPressed: () => context.showSnackbar('Add a new safe zone…'),
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
                    locationLabel: 'Home Park',
                    height: isWide ? 320 : 240,
                    onTap: () => context.showSnackbar('Editing zones on map…'),
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
                        '${zones.length} active',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
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
                          _ZoneRow(zone: zones[i]),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,
                  AppButton.outlined(
                    label: 'Add Safe Zone',
                    icon: Icons.add_rounded,
                    borderRadius: AppRadius.brPill,
                    onPressed: () =>
                        context.showSnackbar('Add a new safe zone…'),
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

// __CONT_1__
/// One safe-zone row: a tinted glyph, the zone name and radius, and a status
/// pill reading "Inside" (accent) or "Outside" (neutral).
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone});

  final _Zone zone;

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
                zone.radius,
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
      ],
    );
  }
}
