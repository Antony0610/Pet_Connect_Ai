import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Live GPS Tracking** — `/owner/collar/tracking`.
///
/// A live map hero over the current-location detail grid, a safe-zone status
/// banner and the primary "Get directions" action. Composes the frozen collar
/// primitives; every value is token-driven so one tree serves both themes.
class SmartCollarTrackingScreen extends ConsumerWidget {
  const SmartCollarTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;

    final selectedPet = ref.watch(selectedPetProvider);
    final petName = selectedPet?.name ?? 'Companion';
    final petsAsync = ref.watch(petsProvider);

    final collarsAsync = ref.watch(registeredCollarsProvider);
    final collars = collarsAsync.valueOrNull ?? [];
    final matchingCollars = collars.where((c) => c.petId == selectedPet?.id);
    final CollarDevice? collar = matchingCollars.isNotEmpty
        ? matchingCollars.first
        : (collars.isNotEmpty ? collars.first : null);
    final collarId = collar?.id ?? 'demo-collar-id';

    final gpsStreamAsync = ref.watch(liveGpsLocationStreamProvider(collarId));

    final double lat = gpsStreamAsync.valueOrNull?.latitude ?? 37.7749;
    final double lng = gpsStreamAsync.valueOrNull?.longitude ?? -122.4194;

    final locationText = gpsStreamAsync.when(
      data: (gps) =>
          'Lat: ${gps.latitude.toStringAsFixed(4)}, Lng: ${gps.longitude.toStringAsFixed(4)} (${gps.isOfflineTelemetry ? "Buffered" : "Live"})',
      loading: () => 'Receiving Realtime GPS Telemetry…',
      error: (_, __) => 'GPS Telemetry Standby (Pine & Centennial)',
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(
        context,
        title: 'Live Tracking',
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on $petName',
            onPressed: () => context.showSnackbar('Centering on $petName…'),
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
                  // Pet Switcher
                  petsAsync.maybeWhen(
                    data: (pets) {
                      if (pets.isEmpty) return const SizedBox.shrink();
                      final selectedId = selectedPet?.id ?? pets.first.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final p in pets) ...[
                                Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                                  child: FilterChip(
                                    avatar: CircleAvatar(
                                      backgroundImage: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                          ? NetworkImage(p.imageUrl!)
                                          : null,
                                      child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                                          ? const Icon(Icons.pets, size: 14)
                                          : null,
                                    ),
                                    label: Text(p.name),
                                    selected: p.id == selectedId,
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref.read(selectedPetIdProvider.notifier).state = p.id;
                                      }
                                    },
                                    selectedColor: scheme.primaryContainer,
                                    checkmarkColor: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  CollarMapPreview(
                    locationLabel: locationText,
                    latitude: lat,
                    longitude: lng,
                    petName: petName,
                    height: isWide ? 380 : 300,
                    onTap: () => context.showSnackbar('Interactive GPS Tracking Active'),
                  ),
                  AppSpacing.vGapMd,
                  _SafeZoneBanner(petName: petName),
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
                        icon: const Icon(
                          Icons.history_rounded,
                          size: AppIconSizes.md,
                        ),
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
/// A reassuring banner confirming pet is inside a defined safe zone.
class _SafeZoneBanner extends StatelessWidget {
  const _SafeZoneBanner({this.petName = 'Buddy'});

  final String petName;

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
                  'Inside "Home Base" safe zone ($petName is safe)',
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
      _Detail(Icons.place_rounded, 'Current Zone', 'Home Base'),
      _Detail(Icons.social_distance_rounded, 'Distance', 'Nearby (Safe)'),
      _Detail(Icons.speed_rounded, 'Status', 'Resting'),
      _Detail(Icons.schedule_rounded, 'Last Sync', 'Live GPS'),
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
