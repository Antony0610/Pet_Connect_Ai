import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_elevation.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_ai_fab.dart';

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
class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final online = PortalPalettes.of(AppPortal.petOwner).accent;
    final isWide = context.screenWidth >= AppBreakpoints.tablet;

    final header = Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'Buddy',
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
              'Connected & Active',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );

    const stats = Row(
      children: [
        Expanded(
          child: CollarStatTile(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: 'Centennial Park',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: CollarStatTile(
            icon: Icons.battery_full_rounded,
            label: 'Battery',
            value: '84%',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: CollarStatTile(
            icon: Icons.signal_cellular_alt_rounded,
            label: 'Signal',
            value: 'Strong',
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
    const dim = 112.0;

    return SizedBox(
      width: dim,
      height: dim,
      child: Stack(
        children: [
          Container(
            width: dim,
            height: dim,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 4),
              boxShadow: AppElevation.soft(context.theme.brightness),
            ),
            child: ClipOval(
              child: Image.network(
                kCollarPetPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: scheme.primaryContainer,
                  child: Icon(
                    Icons.pets_rounded,
                    color: scheme.onPrimaryContainer,
                    size: AppIconSizes.xl,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: online,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today's Activity" — a bordered surface card with the step ring and a
/// "Join Challenge" call to action.
class _TodaysActivity extends StatelessWidget {
  const _TodaysActivity();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      isOutlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Activity",
            style: context.textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Buddy is on track to meet daily goals.',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          Center(
            child: CollarMetricRing(
              progress: 0.65,
              arcColor: scheme.primary,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: scheme.primary,
                    size: AppIconSizes.md,
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    '6,540',
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Steps',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  TextButton.icon(
                    onPressed: () =>
                        context.showSnackbar('Joining the step challenge…'),
                    icon: const Icon(
                      Icons.groups_rounded,
                      size: AppIconSizes.sm,
                    ),
                    label: const Text('Join Challenge'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: context.textTheme.labelLarge?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2×2 quick-action grid: Live Tracking, Lost Mode, Geofence, Diagnostics.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final actions = [
      (
        Icons.my_location_rounded,
        'Live Tracking',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        () => context.goNamed(RouteNames.ownerCollarTracking),
      ),
      (
        Icons.warning_rounded,
        'Lost Mode',
        scheme.errorContainer,
        scheme.onErrorContainer,
        () => context.goNamed(RouteNames.ownerLostMode),
      ),
      (
        Icons.share_location_rounded,
        'Geofence',
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        () => context.goNamed(RouteNames.ownerCollarGeofence),
      ),
      (
        Icons.health_and_safety_rounded,
        'Diagnostics',
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        () => context.goNamed(RouteNames.ownerCollarDiagnostics),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.35,
      children: [
        for (final (icon, label, bg, fg, onTap) in actions)
          CollarActionTile(
            icon: icon,
            label: label,
            background: bg,
            foreground: fg,
            onTap: onTap,
          ),
      ],
    );
  }
}

/// The live mini-map preview; tapping opens full Live Tracking.
class _MiniMap extends StatelessWidget {
  const _MiniMap();

  @override
  Widget build(BuildContext context) {
    return CollarMapPreview(
      locationLabel: 'Centennial Park',
      height: context.screenWidth >= AppBreakpoints.tablet ? 256 : 192,
      onTap: () => context.goNamed(RouteNames.ownerCollarTracking),
    );
  }
}
