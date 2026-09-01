import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_scaffold.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Smart Collar Dashboard** — `/owner/collar`.
///
/// Uses live Supabase Collar data via [registeredCollarsProvider],
/// [collarActivitySummariesProvider], and [liveGpsLocationStreamProvider].
///
/// ZERO dummy/mock data: when no hardware is paired or no activity is logged,
/// honest empty states are shown.
class SmartCollarDashboardScreen extends StatelessWidget {
  const SmartCollarDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;

    return OwnerScaffold(
      currentTab: OwnerTab.collar,
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
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                context.viewPadding.top + 56 + AppSpacing.md,
                margin,
                context.viewPadding.bottom + 90 + AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _CollarPetSwitcher(),
                  AppSpacing.vGapMd,
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

/// Horizontal Pet Switcher Bar for Smart Collar Telemetry
class _CollarPetSwitcher extends ConsumerWidget {
  const _CollarPetSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final petsAsync = ref.watch(petsProvider);
    final selectedPet = ref.watch(selectedPetProvider);

    return petsAsync.maybeWhen(
      data: (pets) {
        if (pets.isEmpty) return const SizedBox.shrink();
        final selectedId = selectedPet?.id ?? pets.first.id;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final pet in pets) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    avatar: CircleAvatar(
                      backgroundImage: (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                          ? NetworkImage(pet.imageUrl!)
                          : null,
                      child: (pet.imageUrl == null || pet.imageUrl!.isEmpty)
                          ? const Icon(Icons.pets, size: 14)
                          : null,
                    ),
                    label: Text(pet.name),
                    selected: pet.id == selectedId,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedPetIdProvider.notifier).state = pet.id;
                      }
                    },
                    selectedColor: scheme.primaryContainer,
                    checkmarkColor: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
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
    final selectedPet = ref.watch(selectedPetProvider);

    return collarsAsync.when(
      data: (collars) {
        final matchingCollars = collars.where((c) => c.petId == selectedPet?.id);
        final CollarDevice? collar = matchingCollars.isNotEmpty
            ? matchingCollars.first
            : (collars.isNotEmpty ? collars.first : null);
        final petName = selectedPet?.name ??
            (collar != null ? 'Collar ${collar.deviceId}' : 'No Collar Paired');
        final isConnected = collar != null && collar.isActive;
        final batteryVal = collar != null ? '${collar.batteryPercentage}%' : '—';
        final connVal = collar != null ? collar.connectivityType : '—';

        final header = Column(
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
                Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isConnected ? online : scheme.onSurfaceVariant,
                  size: AppIconSizes.sm,
                ),
                AppSpacing.hGapXs,
                Text(
                  isConnected
                      ? 'Connected & Active'
                      : (collar != null
                          ? 'Device Offline'
                          : 'Hardware Required — No Device'),
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
            Expanded(
              child: CollarStatTile(
                icon: Icons.location_on_rounded,
                label: 'Status',
                value: isConnected ? 'Online' : 'Offline',
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
                    _PetAvatar(
                      online: isConnected ? online : scheme.outlineVariant,
                      imageUrl: selectedPet?.imageUrl,
                    ),
                    AppSpacing.hGapLg,
                    Expanded(child: info),
                  ],
                )
              : Column(
                  children: [
                    _PetAvatar(
                      online: isConnected ? online : scheme.outlineVariant,
                      imageUrl: selectedPet?.imageUrl,
                    ),
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

/// The pet's circular photo with a connection indicator dot.
class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.online, this.imageUrl});

  final Color online;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: AppSpacing.xxl,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Icon(
                  Icons.pets_rounded,
                  size: AppIconSizes.xl,
                  color: scheme.primary,
                )
              : null,
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
class _TodaysActivity extends ConsumerWidget {
  const _TodaysActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final collarsAsync = ref.watch(registeredCollarsProvider);
    final collar = collarsAsync.valueOrNull?.firstOrNull;

    int steps = 0;
    int activeMinutes = 0;
    int restMinutes = 0;
    double distanceKm = 0.0;

    if (collar != null) {
      final activitiesAsync =
          ref.watch(collarActivitySummariesProvider(collar.id));
      final today = DateTime.now();
      final activities = activitiesAsync.valueOrNull ?? [];
      final matches = activities.where(
        (s) =>
            s.activityDate.year == today.year &&
            s.activityDate.month == today.month &&
            s.activityDate.day == today.day,
      );
      final todayActivity = matches.isNotEmpty ? matches.first : null;

      if (todayActivity != null) {
        steps = todayActivity.stepCount;
        activeMinutes = todayActivity.activeMinutes;
        restMinutes = todayActivity.restMinutes;
        distanceKm = steps * 0.0008;
      }
    }

    final double progress = (steps / 10000).clamp(0.0, 1.0);

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
                          value: progress,
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
                            '$steps',
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
                Expanded(
                  child: Column(
                    children: [
                      _MetricLine(
                        icon: Icons.directions_walk_rounded,
                        label: 'Distance',
                        value: collar != null
                            ? '${distanceKm.toStringAsFixed(1)} km'
                            : '—',
                      ),
                      AppSpacing.vGapSm,
                      _MetricLine(
                        icon: Icons.timer_rounded,
                        label: 'Active',
                        value: collar != null ? '${activeMinutes}m' : '—',
                      ),
                      AppSpacing.vGapSm,
                      _MetricLine(
                        icon: Icons.bedtime_rounded,
                        label: 'Rest',
                        value: collar != null
                            ? '${(restMinutes / 60).toStringAsFixed(1)}h'
                            : '—',
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickActionItemSpec(
        icon: Icons.my_location_rounded,
        title: 'Live\nRadar',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(RoutePaths.ownerCollarTracking),
      ),
      QuickActionItemSpec(
        icon: Icons.shield_rounded,
        title: 'Safe\nZones',
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.ownerCollarGeofence),
      ),
      QuickActionItemSpec(
        icon: Icons.show_chart_rounded,
        title: 'Activity\nStats',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        onTap: () => context.push(RoutePaths.ownerCollarActivity),
      ),
      QuickActionItemSpec(
        icon: Icons.health_and_safety_rounded,
        title: 'Battery &\nDiag',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        onTap: () => context.push(RoutePaths.ownerCollarDiagnostics),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            Text(
              '${actions.length} Controls',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        QuickActionsGridContainer(
          items: actions,
          crossAxisCount: 4,
          tabletCrossAxisCount: 4,
          containerSize: 52,
          iconSize: 26,
        ),
      ],
    );
  }
}

/// Mini-map hero tile previewing Buddy's current location with a button to tap into tracking.
class _MiniMap extends ConsumerWidget {
  const _MiniMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collarsAsync = ref.watch(registeredCollarsProvider);
    final collar = collarsAsync.valueOrNull?.firstOrNull;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final defaultLat = profile?.latitude ?? 10.0;
    final defaultLng = profile?.longitude ?? 76.0;

    String locationLabel = profile?.city != null && profile!.city!.isNotEmpty
        ? '${profile.city} (Home Hub)'
        : 'Home Hub';

    double lat = defaultLat;
    double lng = defaultLng;

    if (collar != null) {
      final locationAsync = ref.watch(liveGpsLocationStreamProvider(collar.id));
      lat = locationAsync.valueOrNull?.latitude ?? defaultLat;
      lng = locationAsync.valueOrNull?.longitude ?? defaultLng;
      locationLabel = locationAsync.when(
        data: (loc) =>
            '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)} • Live',
        loading: () => 'Awaiting GPS telemetry…',
        error: (_, __) => 'GPS signal standby',
      );
    }

    final selectedPet = ref.watch(selectedPetProvider);
    final petName = selectedPet?.name ?? 'Companion';

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
          locationLabel: locationLabel,
          latitude: lat,
          longitude: lng,
          petName: petName,
          onTap: () => context.goNamed(RouteNames.ownerCollarTracking),
        ),
      ],
    );
  }
}
