import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A personalized AI recommendation with a priority and a call to action.
class _Recommendation {
  const _Recommendation({
    required this.icon,
    required this.title,
    required this.detail,
    required this.priority,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final _Priority priority;
  final String action;
}

/// Recommendation priority tiers, mapped to semantic token pairs.
enum _Priority { recommended, suggested, optional }

/// **AI Recommendations** — `/owner/ai/recommendations`.
///
/// AI-curated next steps for the pet's care, each in a gradient-bordered card
/// with a priority badge and an action button. Token-driven; one tree, both
/// themes.
class AiRecommendationsScreen extends ConsumerWidget {
  const AiRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';
    final isCat = pet?.species.toLowerCase() == 'cat';

    final scansAsync = ref.watch(aiHealthScansProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(context, title: 'AI Recommendations'),
      body: scansAsync.when(
        data: (scans) {
          final liveRecs = <_Recommendation>[];
          for (final scan in scans) {
            for (final r in scan.recommendations) {
              liveRecs.add(
                _Recommendation(
                  icon: Icons.health_and_safety_rounded,
                  title: 'Recommendation (${scan.urgencyLevel})',
                  detail: r.toString(),
                  priority: scan.urgencyLevel == 'CRITICAL'
                      ? _Priority.recommended
                      : _Priority.suggested,
                  action: 'View details',
                ),
              );
            }
          }

          final displayRecs = liveRecs.isEmpty
              ? _generateDefaultRecs(petName, isCat)
              : liveRecs;

          return SingleChildScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tailored for $petName',
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Based on recent activity, sleep trends and health passport data.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapLg,
                      for (final item in displayRecs) ...[
                        _RecommendationCard(rec: item),
                        AppSpacing.vGapLg,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load AI recommendations: $err',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<_Recommendation> _generateDefaultRecs(String petName, bool isCat) {
    return [
      _Recommendation(
        icon: isCat ? Icons.sports_baseball_rounded : Icons.directions_walk_rounded,
        title: isCat ? 'Evening laser or wand playtime' : 'Add a gentle evening stroll',
        detail:
            "$petName's energy trends peak in late afternoon. A 15-minute focused play session supports restful sleep.",
        priority: _Priority.recommended,
        action: 'Set reminder',
      ),
      _Recommendation(
        icon: Icons.water_drop_rounded,
        title: 'Hydration & Nutrition Check',
        detail:
            'Maintaining fresh water and tracking caloric intake helps $petName maintain a healthy body condition score.',
        priority: _Priority.optional,
        action: 'Enable tracking',
      ),
    ];
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.rec});

  final _Recommendation rec;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final rec = widget.rec;

    final (label, bg, fg) = switch (rec.priority) {
      _Priority.recommended => (
        'Recommended',
        palette.accentContainer(brightness),
        palette.onAccentContainer(brightness),
      ),
      _Priority.suggested => (
        'Suggested',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _Priority.optional => (
        'Optional',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiCircleIcon(
                icon: _isCompleted ? Icons.check_circle_rounded : rec.icon,
                background: _isCompleted ? Colors.green.withValues(alpha: 0.2) : scheme.primaryContainer,
                foreground: _isCompleted ? Colors.green.shade700 : scheme.onPrimaryContainer,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: _isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
                        fontWeight: AppTypography.semiBold,
                        decoration: _isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    if (_isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      )
                    else
                      AiConfidenceBadge(
                        label: label,
                        background: bg,
                        foreground: fg,
                        icon: Icons.flag_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            rec.detail,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(
                  _isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: _isCompleted ? Colors.green.shade700 : scheme.primary,
                ),
                label: Text(
                  _isCompleted ? 'Mark as Pending' : 'Mark as Done',
                  style: TextStyle(
                    color: _isCompleted ? Colors.green.shade700 : scheme.primary,
                  ),
                ),
                onPressed: () {
                  setState(() => _isCompleted = !_isCompleted);
                  if (_isCompleted) {
                    context.showSnackbar('Marked "${rec.title}" as completed!');
                  }
                },
              ),
              AppButton.text(
                label: rec.action,
                icon: Icons.arrow_forward_rounded,
                iconAlignment: IconAlignment.end,
                onPressed: () => context.showSnackbar('${rec.action} for "${rec.title}"'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
