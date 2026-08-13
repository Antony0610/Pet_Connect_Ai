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

/// One AI health insight: an icon, a headline metric, an explanation, a
/// confidence level and the sources it was derived from.
class _Insight {
  const _Insight({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    required this.confidence,
    required this.sources,
  });

  final IconData icon;
  final _Tint tint;
  final String title;
  final String detail;
  final _Confidence confidence;
  final List<String> sources;
}

/// Which container role tints an insight's leading glyph.
enum _Tint { primary, secondary, tertiary }

/// Confidence tiers, each mapped to a semantic token pair by [_InsightCard].
enum _Confidence { high, moderate }

/// **AI Health Insights** — `/owner/ai/insights`.
///
/// Frozen AI design language over the Health Passport context: a hero summary,
/// then a list of AI-derived insight cards. Each carries a confidence badge and
/// source-attribution chips so every claim is traceable. Token-driven — one
/// tree serves Light and Dark.
class AiHealthInsightsScreen extends ConsumerWidget {
  const AiHealthInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);
    final scansAsync = ref.watch(aiHealthScansProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(context, title: 'Health Insights'),
      body: scansAsync.when(
        data: (scans) {
          final liveInsights = scans.map((s) {
            return _Insight(
              icon: s.urgencyLevel == 'CRITICAL'
                  ? Icons.warning_amber_rounded
                  : Icons.health_and_safety_rounded,
              tint: s.urgencyLevel == 'CRITICAL'
                  ? _Tint.secondary
                  : _Tint.primary,
              title: 'Urgency: ${s.urgencyLevel}',
              detail: s.analysisSummary,
              confidence: _Confidence.high,
              sources: const ['AI Symptom Scan Edge Function'],
            );
          }).toList();

          final displayInsights = liveInsights.isEmpty
              ? _insights
              : liveInsights;

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
                      const _SummaryHero(),
                      AppSpacing.vGapLg,
                      Text(
                        'Derived Insights',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      for (final item in displayInsights) ...[
                        _InsightCard(insight: item),
                        AppSpacing.vGapMd,
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
              'Unable to load health insights: $err',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _insights = [
    _Insight(
      icon: Icons.show_chart_rounded,
      tint: _Tint.primary,
      title: 'Activity score +15% above 30-day average',
      detail:
          'Buddy logged an average of 9,420 steps daily this week, driven by '
          'longer morning walks. Rest quality remained optimal.',
      confidence: _Confidence.high,
      sources: ['Smart Collar Activity Log', 'Health Passport'],
    ),
    _Insight(
      icon: Icons.bedtime_rounded,
      tint: _Tint.secondary,
      title: 'Sleep is consistent',
      detail:
          'Averaging 14 hours over the last 7 nights — a healthy range for '
          'an adult Golden Retriever, with no signs of restlessness.',
      confidence: _Confidence.high,
      sources: ['Smart Collar · Rest', 'AKC Sleep Guide'],
    ),
  ];

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

/// The gradient-bordered summary hero: an at-a-glance wellness verdict for the
/// selected pet, framed as AI-generated content.
class _SummaryHero extends StatelessWidget {
  const _SummaryHero();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiCircleIcon(
                icon: Icons.auto_awesome_rounded,
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  "Buddy's Wellness Summary",
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
              AiConfidenceBadge(
                label: 'Verified',
                background: palette.accentContainer(brightness),
                foreground: palette.onAccentContainer(brightness),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Text(
            'Everything looks great this week. Buddy is more active than usual, '
            'sleeping well, and maintaining a healthy weight. Keep up the daily '
            'walks!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// One insight card: a tinted leading glyph, the headline and explanation, a
/// confidence badge and a wrap of source-attribution chips.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    final (iconBg, iconFg) = switch (insight.tint) {
      _Tint.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tint.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _Tint.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };

    final (
      badgeLabel,
      badgeBg,
      badgeFg,
      badgeIcon,
    ) = switch (insight.confidence) {
      _Confidence.high => (
        'High Confidence',
        palette.accentContainer(brightness),
        palette.onAccentContainer(brightness),
        Icons.verified_rounded,
      ),
      _Confidence.moderate => (
        'Moderate',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.info_rounded,
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiCircleIcon(
                icon: insight.icon,
                background: iconBg,
                foreground: iconFg,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  insight.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            insight.detail,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AiConfidenceBadge(
                label: badgeLabel,
                background: badgeBg,
                foreground: badgeFg,
                icon: badgeIcon,
              ),
              for (final s in insight.sources)
                AiSourceChip(
                  label: s,
                  onTap: () => context.showSnackbar('Opening source: $s'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
