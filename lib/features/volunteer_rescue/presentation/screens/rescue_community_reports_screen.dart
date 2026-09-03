import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class RescueCommunityReportsScreen extends ConsumerStatefulWidget {
  const RescueCommunityReportsScreen({super.key});

  @override
  ConsumerState<RescueCommunityReportsScreen> createState() =>
      _RescueCommunityReportsScreenState();
}

class _RescueCommunityReportsScreenState
    extends ConsumerState<RescueCommunityReportsScreen> {
  int _selectedTab = 0;

  void _openFileSightingDialog() async {
    final petCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('File Community Sighting Intel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: petCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet Name or Species Description',
                  hintText: 'e.g. Golden Retriever or Calico Cat',
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Exact Sighting Location',
                  hintText: 'e.g. Near Cubbon Park East Gate',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Behavior, Direction & Visual Clues',
                  hintText: 'e.g. Heading south toward water, wearing blue collar',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (locCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );

    if (submitted == true && locCtrl.text.trim().isNotEmpty) {
      final alerts = ref.read(activeLostPetAlertsProvider).valueOrNull ?? [];
      final alertId = alerts.isNotEmpty ? alerts.first.id : 'general-alert';
      final currentUser = ref.read(currentUserProfileProvider).valueOrNull;
      final reporterId = currentUser?.id ?? 'volunteer-reporter';

      final newSighting = LostPetSighting(
        id: '',
        alertId: alertId,
        reporterId: reporterId,
        sightingLocation: locCtrl.text.trim(),
        sightingTime: DateTime.now(),
        notes: '${petCtrl.text.trim().isNotEmpty ? "[${petCtrl.text.trim()}] " : ""}${notesCtrl.text.trim()}',
        status: 'VERIFIED',
        createdAt: DateTime.now(),
      );

      final repo = ref.read(rescueRepositoryProvider);
      final result = await repo.reportSighting(newSighting);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit intel: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(allCommunitySightingsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Community sighting report saved to database!')),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sightingsAsync = ref.watch(allCommunitySightingsProvider);
    final sightings = sightingsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Sighting Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.rescueHome);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reports',
            onPressed: () => ref.invalidate(allCommunitySightingsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Report Sighting',
            onPressed: _openFileSightingDialog,
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
                // ── Lead Responder Info Badge ───────────────────────
                _buildLeadResponderCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Sighting Report Feed Tabs ────────────────────────
                Row(
                  children: [
                    _buildTabChoice(
                      theme,
                      colorScheme,
                      index: 0,
                      label: 'Reported Sightings (${sightings.length})',
                    ),
                    AppSpacing.hGapSm,
                    _buildTabChoice(
                      theme,
                      colorScheme,
                      index: 1,
                      label: 'Past Rescues Archive',
                    ),
                  ],
                ),

                AppSpacing.vGapMd,

                // ── Sighting Cards Feed ─────────────────────────────
                if (_selectedTab == 0) ...[
                  if (sightingsAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (sightings.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.radar, size: 48, color: colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Community Sightings',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Citizens haven\'t flagged unverified lost pet sightings recently in this sector. Tap "+" to file new field intel.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('File Sighting Intel'),
                              onPressed: _openFileSightingDialog,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...sightings.map(
                      (sighting) => _buildSightingCard(context, theme, colorScheme, sighting),
                    ),
                ] else
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_edu, size: 48, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Historical Rescue Intel Archive',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All closed rescue missions are archived in the Mission History database.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.archive_outlined),
                            label: const Text('Open Rescue History'),
                            onPressed: () => context.push(RoutePaths.rescueHistory),
                          ),
                        ],
                      ),
                    ),
                  ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadResponderCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.verified_user, color: colorScheme.primary),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Live Incident Sighting Feed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 16, color: colorScheme.primary),
                  ],
                ),
                Text(
                  'Community crowd-sourced telemetry and sightings synchronized in real-time.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChoice(
    ThemeData theme,
    ColorScheme colorScheme, {
    required int index,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = index),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? AppTypography.bold : AppTypography.regular,
      ),
    );
  }

  Widget _buildSightingCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    LostPetSighting sighting,
  ) {
    final isVerified = sighting.status.toUpperCase() == 'VERIFIED';
    final timeStr = DateFormat('MMM d, h:mm a').format(sighting.sightingTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  child: Icon(Icons.person_pin, color: colorScheme.primary),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported: $timeStr',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Field Sighting #${sighting.id.length >= 6 ? sighting.id.substring(0, 6).toUpperCase() : sighting.id}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: isVerified ? 'Verified' : 'Unverified',
                  backgroundColor: isVerified
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  textColor: isVerified ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sighting.sightingLocation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (sighting.notes != null && sighting.notes!.isNotEmpty) ...[
              AppSpacing.vGapXs,
              Text(
                sighting.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share Intel'),
                  onPressed: () {
                    ExternalActions.shareText(
                      '🚨 Sighting Reported\n'
                      'Location: ${sighting.sightingLocation}\n'
                      'Notes: ${sighting.notes ?? "No additional notes"}\n'
                      'Time: $timeStr',
                      subject: 'Lost Pet Sighting Intel',
                    );
                  },
                ),
                AppSpacing.hGapSm,
                FilledButton.icon(
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Dispatch / Search'),
                  onPressed: () => context.push(RoutePaths.rescueOperations),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
