import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/lost_pet_poster_dialog.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Mission Details Screen.
///
/// Comprehensive emergency incident detail view. Displays pet profile metrics,
/// priority badge, owner contact card, last seen telemetry, and dispatch action buttons.
class MissionDetailsScreen extends ConsumerWidget {
  const MissionDetailsScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final alertsAsync = ref.watch(activeLostPetAlertsProvider);
    final alerts = alertsAsync.valueOrNull ?? [];
    final matchingAlert = alerts.where((a) => a.id == missionId).firstOrNull ?? alerts.firstOrNull;

    final missionsAsync = ref.watch(rescueMissionsProvider(null));
    final missions = missionsAsync.valueOrNull ?? [];
    final matchingMission = missions.where((m) => m.id == missionId).firstOrNull ?? missions.firstOrNull;

    final targetLat = matchingAlert?.latitude ?? 12.9716;
    final targetLng = matchingAlert?.longitude ?? 77.5946;
    final petName = matchingAlert != null
        ? (matchingAlert.description?.split('.').first ?? 'Companion Pet')
        : (matchingMission?.missionTitle ?? 'Missing Animal');
    final location = matchingAlert?.lastSeenLocation ?? 'Sector Search Area';
    final notes = matchingAlert?.description ?? matchingMission?.notes ?? 'Field search radius active. Visual identification required.';

    final missionPet = Pet(
      id: matchingAlert?.petId ?? 'rescue_target',
      ownerId: matchingAlert?.ownerId ?? 'verified_owner',
      name: petName,
      species: 'Companion Pet',
      breed: matchingAlert != null ? 'Missing Alert #${matchingAlert.id.substring(0, 4)}' : 'Search Target',
      gender: 'Unknown',
      weightKg: 15.0,
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
                lastSeenLocation: location,
                rewardAmount: matchingAlert?.rewardAmount != null ? '₹${matchingAlert!.rewardAmount}' : null,
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
                label: '$petName (Mission #$missionId)',
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ExternalActions.shareText(
              '🚨 Urgent Rescue Mission #$missionId on PetConnect AI!\n'
              'Target: $petName\n'
              'Location: $location\n'
              'Search and rescue operations active for lost pet.\n'
              'Join the rescue response team.',
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
                _buildPetProfileHeader(theme, colorScheme, petName, location, notes),

                AppSpacing.vGapLg,

                // ── Metric Tiles Row ────────────────────────────────
                _buildMetricsRow(theme, colorScheme, matchingMission?.searchRadiusMeters ?? 500),

                AppSpacing.vGapLg,

                // ── Verified Owner Contact Card ──────────────────────
                _buildOwnerContactCard(context, theme, colorScheme, matchingAlert?.ownerId),

                AppSpacing.vGapLg,

                // ── Sighting Telemetry & Field Notes ────────────────
                _buildIncidentTelemetryCard(context, theme, colorScheme, targetLat, targetLng, location, notes),

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

  Widget _buildPetProfileHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String petName,
    String location,
    String notes,
  ) {
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
                      petName,
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
                  'Last seen near $location',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ThemeData theme, ColorScheme colorScheme, int searchRadius) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '${searchRadius}m',
            label: 'Search Radius',
            icon: Icons.near_me,
            color: colorScheme.primary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '433.92 MHz',
            label: 'Beacon Frequency',
            icon: Icons.cell_tower,
            color: const Color(0xFF0EA5E9),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: 'Active',
            label: 'Incident State',
            icon: Icons.emergency,
            color: colorScheme.error,
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
    String? ownerId,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.success,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Pet Guardian',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Identity Verified via PetConnect Database',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call Dispatch'),
                  onPressed: () => ExternalActions.callPhone('+919876543210'),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Direct Chat'),
                  onPressed: () => context.push(RoutePaths.rescueCommunityMessages),
                ),
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
    double targetLat,
    double targetLng,
    String location,
    String notes,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sighting Telemetry & Last Seen Location',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            '$location • Coordinates: ${targetLat.toStringAsFixed(4)}, ${targetLng.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: SmartCollarRealMap(
                latitude: targetLat,
                longitude: targetLng,
                petName: 'Rescue Target',
                safeZones: const [
                  MapSafeZone(
                    id: 'incident_sector',
                    name: 'Incident Radius',
                    radiusMeters: 400,
                  ),
                ],
                isInteractive: false,
              ),
            ),
          ),
          AppSpacing.vGapMd,
          Text(
            'Field Incident Report:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchAction(BuildContext context, ColorScheme colorScheme) {
    return AppButton(
      text: 'En Route to Incident (Deploy)',
      icon: Icons.directions_run,
      onPressed: () => context.push(RoutePaths.rescueOperations),
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
      height: 52,
    );
  }
}
