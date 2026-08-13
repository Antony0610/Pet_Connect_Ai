import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
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

          final displayRecs = liveRecs.isEmpty ? _recs : liveRecs;

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
                        'Tailored for Buddy',
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

  static const _recs = [
    _Recommendation(
      icon: Icons.directions_walk_rounded,
      title: 'Add a short evening walk',
      detail:
          "Buddy's energy peaks after 6pm. A 15-minute walk would help him "
          'settle and supports the higher activity trend.',
      priority: _Priority.recommended,
      action: 'Set reminder',
    ),
    _Recommendation(
      icon: Icons.water_drop_rounded,
      title: 'Track water intake',
      detail:
          'Logging water on warmer days gives more accurate hydration '
          'insights over summer.',
      priority: _Priority.optional,
      action: 'Enable tracking',
    ),
  ];

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec});

  final _Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

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
                icon: rec.icon,
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    AppSpacing.vGapXs,
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
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              label: rec.action,
              icon: Icons.arrow_forward_rounded,
              iconAlignment: IconAlignment.end,
              onPressed: () => context.showSnackbar('${rec.action}…'),
            ),
          ),
        ],
      ),
    );
  }
}
