import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/geo_distance_helper.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/lost_pet_poster_dialog.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Mission Details Screen (Stitch ID: `fa93767d86604d7f886359d445ae5904`).
///
/// Comprehensive emergency incident detail view. Displays pet profile metrics,
/// priority badge, owner contact card, last seen telemetry, and dispatch action buttons.
class MissionDetailsScreen extends StatelessWidget {
  const MissionDetailsScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  static const double targetLat = 12.9716;
  static const double targetLng = 77.5946;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const missionPet = Pet(
      id: 'pet_rescue_luna',
      ownerId: 'owner_sarah',
      name: 'Luna',
      species: 'dog',
      breed: 'Siberian Husky',
      gender: 'female',
      weightKg: 21.0,
      microchipId: '985141002349812',
      healthStatus: 'urgent',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Generate Rescue Poster',
            onPressed: () {
              HapticFeedback.lightImpact();
              LostPetPosterDialog.show(
                context,
                pet: missionPet,
                lastSeenLocation: 'Cubbon Park Trailhead, Sector 4',
                rewardAmount: '\$500',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigation_outlined),
            tooltip: 'Launch Turn-by-Turn GPS',
            onPressed: () {
              HapticFeedback.lightImpact();
              ExternalActions.openMapDirections(
                latitude: targetLat,
                longitude: targetLng,
                label: 'Luna (Mission #$missionId)',
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ExternalActions.shareText(
              '🚨 Urgent Rescue Mission #$missionId on PetConnect AI!\nSearch and rescue operations active for lost pet.\nJoin the rescue response team.',
              subject: 'Rescue Mission #$missionId',
            ),
            tooltip: 'Share Mission',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pet Profile Header Banner ────────────────────────
                _buildPetProfileHeader(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Metric Tiles Row ────────────────────────────────
                _buildMetricsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Verified Owner Contact Card ──────────────────────
                _buildOwnerContactCard(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Sighting Telemetry & Field Notes ────────────────
                _buildIncidentTelemetryCard(context, theme, colorScheme),

                AppSpacing.vGapXl,

                // ── Dispatch CTA Action Button ──────────────────────
                _buildDispatchAction(context, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.pets, size: 32, color: colorScheme.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Luna',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    const AppChip(
                      label: 'HIGH PRIORITY',
                      backgroundColor: AppColors.lightError,
                      textColor: AppColors.white,
                    ),
                  ],
                ),
                Text(
                  'Siberian Husky • Female • 3 years old',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Silver & White coat, blue eyes • Wearing red collar with tag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '1.3 km',
            label: 'Distance Away',
            icon: Icons.near_me,
            color: colorScheme.primary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '15m ago',
            label: 'Last Sighting',
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '3 En Route',
            label: 'Active Responders',
            icon: Icons.group,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          AppSpacing.vGapXs,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerContactCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sarah Connor',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Verified Owner • Distraught',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.success),
                onPressed: () => ExternalActions.callPhoneNumber('+15551234567'),
                tooltip: 'Call Owner',
              ),
              IconButton(
                icon: Icon(Icons.chat, color: colorScheme.primary),
                onPressed: () => context.push(RoutePaths.ownerCommunityMessages),
                tooltip: 'Message Owner',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTelemetryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Text(
                'Last Known Coordinates & Field Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Cubbon Park Trailhead, Sector 4 (12.9716° N, 77.5946° E)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Luna bolted after loud construction noise near the trailhead. Friendly with humans, but spooked by sudden movements. Collar emits low-power BLE beacon.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: const SmartCollarRealMap(
              height: 180,
              latitude: 12.9716,
              longitude: 77.5946,
              locationLabel: 'Last Known Location',
              petName: 'Luna',
            ),
          ),
          AppSpacing.vGapSm,
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transit Proximity: ${GeoDistanceHelper.formatDistanceWithEta(startLatitude: 12.9780, startLongitude: 77.5900, endLatitude: 12.9716, endLongitude: 77.5946)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ExternalActions.openMapDirections(
                    latitude: targetLat,
                    longitude: targetLng,
                    label: 'Luna Rescue Incident',
                    context: context,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Open in Maps', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchAction(BuildContext context, ColorScheme colorScheme) {
    return AppButton(
      text: 'Accept & Begin Mission',
      icon: Icons.check_circle,
      isFullWidth: true,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission Accepted! Navigating...')),
        );
        context.push('/rescue/missions/$missionId/accepted');
      },
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
      height: 48,
    );
  }
}
