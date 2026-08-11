import 'package:flutter/material.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
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
class AiRecommendationsScreen extends StatelessWidget {
  const AiRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);

    const recs = [
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
        icon: Icons.restaurant_rounded,
        title: 'Fine-tune evening portion',
        detail:
            'Consider increasing dinner by ~5% to match activity. Confirm the '
            "exact amount with Buddy's vet first.",
        priority: _Priority.suggested,
        action: 'Ask a vet',
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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(context, title: 'Recommendations'),
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
                  Text(
                    'Personalized for Buddy',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    'AI-curated next steps based on his latest health and '
                    'activity data.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapLg,
                  for (var i = 0; i < recs.length; i++) ...[
                    if (i > 0) AppSpacing.vGapMd,
                    _RecommendationCard(rec: recs[i]),
                  ],
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
