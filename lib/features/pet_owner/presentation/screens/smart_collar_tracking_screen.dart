import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/collar_widgets.dart';

/// **Live GPS Tracking** — `/owner/collar/tracking`.
///
/// A live map hero over the current-location detail grid, a safe-zone status
/// banner and the primary "Get directions" action. Composes the frozen collar
/// primitives; every value is token-driven so one tree serves both themes.
class SmartCollarTrackingScreen extends StatelessWidget {
  const SmartCollarTrackingScreen({super.key});

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
        title: 'Live Tracking',
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on Buddy',
            onPressed: () => context.showSnackbar('Centering on Buddy…'),
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
                    locationLabel: 'Centennial Park',
                    height: isWide ? 360 : 280,
                    onTap: () => context.showSnackbar('Expanding live map…'),
                  ),
                  AppSpacing.vGapMd,
                  const _SafeZoneBanner(),
                  AppSpacing.vGapLg,
                  Text(
                    'Location Details',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  _DetailGrid(isWide: isWide),
                  AppSpacing.vGapLg,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Get Directions',
                          icon: Icons.directions_rounded,
                          borderRadius: AppRadius.brPill,
                          onPressed: () =>
                              context.showSnackbar('Opening directions…'),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      IconButton.outlined(
                        onPressed: () =>
                            context.showSnackbar('Location history…'),
                        icon: const Icon(Icons.history_rounded,
                            size: AppIconSizes.md),
                        tooltip: 'Location history',
                      ),
                    ],
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
/// A reassuring banner confirming Buddy is inside a defined safe zone.
class _SafeZoneBanner extends StatelessWidget {
  const _SafeZoneBanner();

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.accentContainer(brightness),
        borderRadius: AppRadius.brCard,
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: palette.onAccentContainer(brightness),
            size: AppIconSizes.md,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inside "Home Park" safe zone',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: palette.onAccentContainer(brightness),
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  'Updated just now · GPS accuracy ±4 m',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: palette.onAccentContainer(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled current-location fact.
class _Detail {
  const _Detail(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// A responsive grid of current-location details (place, distance, speed,
/// last update) rendered as collar stat tiles.
class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    const details = [
      _Detail(Icons.place_rounded, 'Current place', 'Centennial Park'),
      _Detail(Icons.social_distance_rounded, 'Distance', '1.2 km away'),
      _Detail(Icons.speed_rounded, 'Speed', 'Resting'),
      _Detail(Icons.schedule_rounded, 'Last update', 'Just now'),
    ];

    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        for (final d in details)
          CollarStatTile(icon: d.icon, label: d.label, value: d.value),
      ],
    );
  }
}
