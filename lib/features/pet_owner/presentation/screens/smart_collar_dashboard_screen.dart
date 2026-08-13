import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_ai_fab.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Smart Collar Dashboard** — `/owner/collar`.
///
/// The frozen Stitch comp: a glass device-status card (pet, connection, and a
/// Location / Battery / Signal stat grid), a "Today's Activity" step ring beside
/// a 2×2 quick-action grid, and a live mini-map preview — with the floating AI
/// assistant docked above. Every value comes from tokens / theme, so one tree
/// serves Light and Dark.
class SmartCollarDashboardScreen extends StatelessWidget {
  const SmartCollarDashboardScreen({super.key});

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
        title: 'Smart Collar',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Collar settings',
            onPressed: () => context.goNamed(RouteNames.ownerCollarSettings),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OwnerAiFab(
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
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
                  const _DeviceStatusCard(),
                  AppSpacing.vGapLg,
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TodaysActivity()),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(child: _QuickActions()),
                      ],
                    )
                  else ...[
                    const _TodaysActivity(),
                    AppSpacing.vGapLg,
                    const _QuickActions(),
                  ],
                  AppSpacing.vGapLg,
                  const _MiniMap(),
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

/// The glass device-status hero: the pet's photo with an online indicator, the
/// name and connection line, and a Location / Battery / Signal stat grid.
class _DeviceStatusCard extends ConsumerWidget {
  const _DeviceStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final online = PortalPalettes.of(AppPortal.petOwner).accent;
    final isWide = context.screenWidth >= AppBreakpoints.tablet;
    final collarsAsync = ref.watch(registeredCollarsProvider);

    return collarsAsync.when(
      data: (collars) {
        final collar = collars.isNotEmpty ? collars.first : null;
        final petName = collar != null
            ? 'Collar ${collar.deviceId}'
            : 'Buddy (No Hardware)';
        final batteryVal = collar != null
            ? '${collar.batteryPercentage}%'
            : 'Software Only';
        final connVal = collar != null
            ? collar.connectivityType
            : 'No Hardware';

        final header = Column(
          crossAxisAlignment: isWide
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(
              petName,
              style: context.textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: AppTypography.bold,
              ),
            ),
            AppSpacing.vGapXs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_rounded, color: online, size: AppIconSizes.sm),
                AppSpacing.hGapXs,
                Text(
                  collar != null
                      ? 'Connected & Active'
                      : 'Software Service Active',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );

        final stats = Row(
          children: [
            const Expanded(
              child: CollarStatTile(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: 'Centennial Park',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CollarStatTile(
                icon: Icons.battery_full_rounded,
                label: 'Battery',
                value: batteryVal,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CollarStatTile(
                icon: Icons.cell_tower_rounded,
                label: 'Signal',
                value: connVal,
              ),
            ),
          ],
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, AppSpacing.vGapMd, stats],
        );

        return GlassCard(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PetAvatar(online: online),
                    AppSpacing.hGapLg,
                    Expanded(child: info),
                  ],
                )
              : Column(
                  children: [
                    _PetAvatar(online: online),
                    AppSpacing.vGapMd,
                    info,
                  ],
                ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Unable to load collar device.',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
        ),
      ),
    );
  }
}

/// The pet's circular photo with a green "online" indicator dot, matching the
/// frozen device-status hero.
class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.online});

  final Color online;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: AppSpacing.xxl,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
          child: Icon(
            Icons.pets_rounded,
            size: AppIconSizes.xl,
            color: scheme.primary,
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: online,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 2),
          ),
        ),
      ],
    );
  }
}

/// "Today's Activity" hero tile: a circular step progress ring with center text
/// beside a vertical breakdown stack (Distance, Active, Rest).
class _TodaysActivity extends StatelessWidget {
  const _TodaysActivity();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      backgroundColor: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Activity",
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            AppSpacing.vGapLg,
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: 8420 / 10000,
                          strokeWidth: 10,
                          backgroundColor: scheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          color: scheme.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '8,420',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          Text(
                            'steps',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapLg,
                const Expanded(
                  child: Column(
                    children: [
                      _MetricLine(
                        icon: Icons.directions_walk_rounded,
                        label: 'Distance',
                        value: '5.2 km',
                      ),
                      AppSpacing.vGapSm,
                      _MetricLine(
                        icon: Icons.timer_rounded,
                        label: 'Active',
                        value: '1h 45m',
                      ),
                      AppSpacing.vGapSm,
                      _MetricLine(
                        icon: Icons.bedtime_rounded,
                        label: 'Rest',
                        value: '14h 20m',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Icon(icon, size: AppIconSizes.sm, color: scheme.primary),
        AppSpacing.hGapXs,
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}

/// 2×2 quick-action grid linking into the child collar routes.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapSm,
        Row(
          children: [
            Expanded(
              child: CollarActionTile(
                icon: Icons.my_location_rounded,
                label: 'Live Tracking',
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
                onTap: () => context.goNamed(RouteNames.ownerCollarTracking),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CollarActionTile(
                icon: Icons.shield_rounded,
                label: 'Safe Zones',
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                onTap: () => context.goNamed(RouteNames.ownerCollarGeofence),
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: CollarActionTile(
                icon: Icons.show_chart_rounded,
                label: 'Activity',
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                onTap: () => context.goNamed(RouteNames.ownerCollarActivity),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CollarActionTile(
                icon: Icons.health_and_safety_rounded,
                label: 'Diagnostics',
                background: scheme.errorContainer,
                foreground: scheme.onErrorContainer,
                onTap: () => context.goNamed(RouteNames.ownerCollarDiagnostics),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mini-map hero tile previewing Buddy's current location with a button to tap into tracking.
class _MiniMap extends StatelessWidget {
  const _MiniMap();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Preview',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapSm,
        CollarMapPreview(
          locationLabel: 'Centennial Park • 2m ago',
          onTap: () => context.goNamed(RouteNames.ownerCollarTracking),
        ),
      ],
    );
  }
}
