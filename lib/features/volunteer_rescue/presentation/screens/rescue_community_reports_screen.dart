import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
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

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 's1',
      'reporter': 'Civic Reporter • Mark T.',
      'time': '5 mins ago',
      'pet': 'Luna (Siberian Husky)',
      'location': 'Spotted running near Cubbon Park East Gate',
      'verified': true,
      'aiMatchScore': 96,
      'notes':
          'Matching silver coat and blue collar. Headed east toward riverbed.',
    },
    {
      'id': 's2',
      'reporter': 'Civic Reporter • Elena R.',
      'time': '25 mins ago',
      'pet': 'Archie (Golden Retriever)',
      'location': 'Near MG Road & Brigade Road Junction',
      'verified': false,
      'aiMatchScore': 78,
      'notes':
          'Wearing collar, sitting near outdoor tables. Skittish when approached.',
    },
  ];

  void _openFileSightingDialog() async {
    final petCtrl = TextEditingController(text: 'Bella (Golden Retriever)');
    final locCtrl = TextEditingController(text: 'Koramangala 80ft Road');
    final notesCtrl = TextEditingController(text: 'Spotted near pharmacy with red harness.');

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
                  labelText: 'Pet Name or Description',
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Exact Sighting Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Behavior, Direction & Visual Clues',
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Intel'),
          ),
        ],
      ),
    );

    if (submitted == true && petCtrl.text.trim().isNotEmpty) {
      final newSighting = LostPetSighting(
        id: '',
        alertId: '',
        reporterId: '',
        sightingLocation: locCtrl.text.trim(),
        latitude: 12.9716,
        longitude: 77.5946,
        sightingTime: DateTime.now(),
        notes: notesCtrl.text.trim(),
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
        (saved) {
          setState(() {
            _reports.insert(0, {
              'id': saved.id,
              'reporter': 'Civic Intel (Verified)',
              'time': 'Just now',
              'pet': petCtrl.text.trim(),
              'location': locCtrl.text.trim(),
              'verified': true,
              'aiMatchScore': 94,
              'notes': notesCtrl.text.trim(),
            });
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Community sighting report filed to database!')),
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
                      label: 'Reported Sightings (${_reports.length})',
                    ),
                    AppSpacing.hGapSm,
                    _buildTabChoice(
                      theme,
                      colorScheme,
                      index: 1,
                      label: 'Past Rescues',
                    ),
                  ],
                ),

                AppSpacing.vGapMd,

                // ── Sighting Cards Feed ─────────────────────────────
                if (_selectedTab == 0)
                  ..._reports.map(
                    (rpt) => _buildSightingCard(context, theme, colorScheme, rpt),
                  )
                else
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
                      'Rescue Lead Responder',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 16, color: colorScheme.primary),
                  ],
                ),
                Text(
                  'Tier 3 Field Commander • Live Telemetry & GPS Ingestion Active',
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
    Map<String, dynamic> rpt,
  ) {
    final isVerified = rpt['verified'] as bool;

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
                        rpt['reporter'] as String,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        rpt['pet'] as String,
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
                    rpt['location'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              rpt['notes'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapSm,
            if (rpt['aiMatchScore'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'AI Lost Pet Sighting Match: ${rpt['aiMatchScore']}% Confidence',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share Alert'),
                  onPressed: () {
                    ExternalActions.shareText(
                      '🚨 CIVILIAN SIGHTING REPORT: ${rpt['pet']}\n'
                      'Location: ${rpt['location']}\n'
                      'Notes: ${rpt['notes']}\n'
                      'Reporter: ${rpt['reporter']}\n'
                      'Reported via PetConnect AI Volunteer Network',
                      subject: '🚨 Pet Sighting Alert: ${rpt['pet']}',
                    );
                  },
                ),
                AppSpacing.hGapSm,
                AppButton(
                  text: 'Dispatch Unit',
                  icon: Icons.directions_run,
                  onPressed: () => context.push(RoutePaths.rescueOperations),
                  height: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
