import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Sightings**
/// (Light Theme design authority, ID `45c1a15c`).
///
/// Displays community sighting reports, AI-driven probability clusters, and
/// location coordinates for missing pets.
class CommunitySightingsScreen extends ConsumerStatefulWidget {
  const CommunitySightingsScreen({super.key});

  @override
  ConsumerState<CommunitySightingsScreen> createState() =>
      _CommunitySightingsScreenState();
}

class _CommunitySightingsScreenState
    extends ConsumerState<CommunitySightingsScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'Nearby';

  final List<String> _filters = const ['Nearby', 'Recent', 'Verified'];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Community Sightings',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emergency_share, color: scheme.error),
            tooltip: 'Emergency Alert',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Emergency broadcast active for $petName')),
              );
            },
          ),
        ],
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
                // ── Banner Description ──────────────────────────────
                Text(
                  "Recent community reports matching $petName's description in your area. AI analysis suggests a high probability cluster near Pine St.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapMd,

                // ── Filter Chips Row ────────────────────────────────
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Cluster Match Banner ────────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'AI High Probability Cluster',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          const AiConfidenceBadge(percentage: '92%'),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'MG Road Junction',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Reported by Sarah J. • 15 mins ago • 400 m away',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: scheme.primary),
                          AppSpacing.hGapXs,
                          Text(
                            'Verified Sighting',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          AppButton.filled(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Pine St. Sighting Map...',
                                  ),
                                ),
                              );
                            },
                            size: AppButtonSize.small,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map, size: 14),
                                SizedBox(width: 4),
                                Text('View on Map'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Sightings Feed List ────────────────────────────
                const SectionHeader(title: 'Recent Sighting Reports'),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  title: 'Cubbon Park North Entrance',
                  reporter: 'Reported by Mike T.',
                  timeAgo: '2 hours ago',
                  distance: '1.2 km away',
                  confidence: 68,
                ),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  title: 'Jayanagar 4th Block',
                  reporter: 'Reported anonymously',
                  timeAgo: '5 hours ago',
                  distance: '2.5 km away',
                  confidence: 45,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReportSightingModal(context, petName),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report Sighting'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  void _openReportSightingModal(BuildContext context, String petName) {
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String photoSource = 'None';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_location_alt_rounded,
                          color: context.colorScheme.primary,
                          size: 24,
                        ),
                        AppSpacing.hGapSm,
                        Text(
                          'Report Pet Sighting',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  'Help reunite lost companions. Broadcast verified location and photos to nearby owners.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sighting Location / Cross Street',
                    hintText: 'e.g. Pine St & 4th Ave near Central Park',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description & Appearance',
                    hintText: 'e.g. Golden Retriever mix with red collar, looked well-fed...',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Reporter Contact Phone (Optional)',
                    hintText: 'e.g. +1 555-0199',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vGapMd,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: photoSource == 'Camera'
                              ? context.colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                        ),
                        onPressed: () => setModalState(() => photoSource = 'Camera'),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: photoSource == 'Gallery'
                              ? context.colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                        ),
                        onPressed: () => setModalState(() => photoSource = 'Gallery'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Submit Community Sighting'),
                    onPressed: () {
                      final loc = locationCtrl.text.trim();
                      if (loc.isEmpty) {
                        context.showSnackbar('Please specify the sighting location.');
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sighting reported at "$loc". AI cluster updated!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    },
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
    required String title,
    required String reporter,
    required String timeAgo,
    required String distance,
    required int confidence,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: scheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              AiConfidenceBadge(percentage: '$confidence%'),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            '$reporter • $timeAgo • $distance',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.outlined(
              onPressed: () => context.goNamed(RouteNames.ownerCollarTracking),
              size: AppButtonSize.small,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 14),
                  SizedBox(width: 4),
                  Text('View on Map'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
