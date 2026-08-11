import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Lost Pet Dashboard**
/// (Light Theme design authority, ID `82c81261d1574d6ea6bfbb20d6ab62bb`).
///
/// Centralized emergency command dashboard connecting collar Lost Mode radar,
/// community sighting reports, AI probability matches, and volunteer dispatch.
class LostPetDashboardScreen extends StatefulWidget {
  const LostPetDashboardScreen({super.key});

  @override
  State<LostPetDashboardScreen> createState() => _LostPetDashboardScreenState();
}

class _LostPetDashboardScreenState extends State<LostPetDashboardScreen> {
  static const double _maxContentWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Lost Pet Dashboard',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.error,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Active Lost Mode Hero Banner ───────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: scheme.error,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'EMERGENCY BROADCAST ACTIVE',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text('RADAR PULSE'),
                            backgroundColor: scheme.errorContainer,
                            labelStyle: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: AppTypography.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Text(
                        'Missing: Max (Golden Retriever)',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Broadcasting emergency beacon within a 5-mile radius. Smart collar telemetry is actively transmitting GPS pulse.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapLg,

                      // ── Last Known Telemetry ─────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: scheme.primary,
                                  size: 20,
                                ),
                                AppSpacing.hGapSm,
                                Text(
                                  'Last Known: Maple Park, 2 mins ago',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: AppTypography.bold,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  'Accuracy: 5m',
                                  style: context.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            AppSpacing.vGapSm,
                            LinearProgressIndicator(
                              value: 0.92,
                              color: scheme.error,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vGapLg,

                      // ── Emergency Action Buttons ──────────────────
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.filled(
                              onPressed: () => context.goNamed(
                                RouteNames.ownerCollarTracking,
                              ),
                              child: const Text('Live GPS Radar'),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          AppButton.outlined(
                            onPressed: () => context.goNamed(
                              RouteNames.ownerCommunitySightings,
                            ),
                            child: const Text('Community Sightings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Community Sightings Feed ───────────────────────
                const SectionHeader(title: 'Recent Sightings Near You'),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  reporter: 'Alex Johnson',
                  location: 'Pine Street & 5th Ave (0.4 mi away)',
                  time: '5 mins ago',
                  confidence: '92% AI Match',
                ),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  reporter: 'Volunteer Sarah',
                  location: 'Centennial Park Entrance',
                  time: '18 mins ago',
                  confidence: '85% AI Match',
                ),
                AppSpacing.vGapXl,

                // ── Emergency Resolution Control ──────────────────
                AppCard(
                  backgroundColor: scheme.surfaceContainerHigh,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: scheme.primary,
                        size: 28,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Found your pet?',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              'Deactivate Lost Mode to stop emergency radar broadcasts.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton.text(
                        onPressed: () {
                          setState(() => _isLostModeActive = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lost Mode deactivated successfully',
                              ),
                            ),
                          );
                        },
                        child: const Text('Safe & Sound'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSightingCard(
    BuildContext context, {
    required String reporter,
    required String location,
    required String time,
    required String confidence,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      onTap: () => context.goNamed(RouteNames.ownerCommunitySightings),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Icon(
              Icons.remove_red_eye,
              color: scheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reporter,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(confidence),
                      backgroundColor: scheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 10,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
                Text(location, style: context.textTheme.bodySmall),
                Text(
                  time,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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
