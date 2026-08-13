import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **AI Hub Dashboard** — `/owner/ai`.
///
/// Frozen Stitch comp: a personal greeting, the signature gradient-bordered
/// "Your AI Assistant is ready" hero, a "Today's Insight" card with a High
/// Confidence badge, a Quick Actions grid and a Recent Activity list. Every
/// value comes from tokens / theme so one tree serves Light and Dark.
class AiHubDashboardScreen extends StatelessWidget {
  const AiHubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(context, title: 'AI Hub'),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Greeting(),
                  AppSpacing.vGapLg,
                  _AssistantHero(),
                  AppSpacing.vGapLg,
                  _InsightCard(),
                  AppSpacing.vGapLg,
                  _QuickActions(),
                  AppSpacing.vGapLg,
                  _RecentActivity(),
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

/// The personal greeting: an `h2`-scale name over a muted subtitle.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello Sarah',
          style: context.textTheme.headlineMedium?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          'Here is your daily pet wellness overview.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The gradient-bordered AI hero card: headline, a friendly status line and a
/// primary "Start Conversation" pill that opens the assistant chat.
class _AssistantHero extends StatelessWidget {
  const _AssistantHero();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI Assistant is ready',
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            "I've analyzed Buddy's latest health data. Everything looks "
            'fantastic today!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Start Conversation',
              icon: Icons.smart_toy_rounded,
              borderRadius: AppRadius.brPill,
              onPressed: () => context.goNamed(RouteNames.ownerAiChat),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today's Insight": a High-Confidence badge, a lightbulb glyph, the insight
/// copy and a footer that taps through to the full insights screen.
class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return AppCard(
      backgroundColor: scheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiConfidenceBadge(
                label: 'High Confidence',
                background: palette.accentContainer(brightness),
                foreground: palette.onAccentContainer(brightness),
              ),
              const Spacer(),
              Icon(
                Icons.lightbulb_rounded,
                color: scheme.tertiary,
                size: AppIconSizes.md,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            "Today's Insight",
            style: context.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapXs,
          Text.rich(
            TextSpan(
              style: context.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
              ),
              children: [
                const TextSpan(text: "Buddy's activity is up "),
                TextSpan(
                  text: '15%',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const TextSpan(text: '. This matches the '),
                TextSpan(
                  text: 'Top 5%',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const TextSpan(text: ' of active pets in the community!'),
              ],
            ),
          ),
          AppSpacing.vGapMd,
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          AppSpacing.vGapXs,
          Row(
            children: [
              Text(
                'Based on last 7 days',
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.goNamed(RouteNames.ownerAiInsights),
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
                iconAlignment: IconAlignment.end,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: AppIconSizes.sm,
                ),
                label: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One quick-action: label, glyph, tinted circular icon and a tap target.
class _Action {
  const _Action(this.icon, this.label, this.onTap, this.tint);

  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;
  final _Tint tint;
}

/// Which container role tints an action's circular icon.
enum _Tint { primary, secondary, tertiary }

/// The Quick Actions grid: 2 columns on mobile, 5 across on wide layouts,
/// matching the frozen bento row.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final columns = width < AppBreakpoints.tablet ? 2 : 5;

    final actions = <_Action>[
      _Action(
        Icons.forum_rounded,
        'Ask AI',
        (c) => c.goNamed(RouteNames.ownerAiChat),
        _Tint.primary,
      ),
      _Action(
        Icons.image_search_rounded,
        'Analyze Image',
        (c) => c.goNamed(RouteNames.ownerAiAnalysis),
        _Tint.secondary,
      ),
      _Action(
        Icons.camera_alt_outlined,
        'AI HUD Scanner',
        (c) => c.goNamed(RouteNames.ownerAiScan),
        _Tint.primary,
      ),
      _Action(
        Icons.assessment_rounded,
        'View Reports',
        (c) => c.goNamed(RouteNames.ownerAiReports),
        _Tint.tertiary,
      ),
      _Action(
        Icons.groups_rounded,
        'Community Hub',
        (c) => c.goNamed(RouteNames.ownerCommunity),
        _Tint.primary,
      ),
      _Action(
        Icons.monitor_heart_rounded,
        'Health Trends',
        (c) => c.goNamed(RouteNames.ownerHealthGrowth),
        _Tint.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapMd,
        GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final a in actions) _ActionTile(action: a)],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _Action action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, fg) = switch (action.tint) {
      _Tint.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tint.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _Tint.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: AppRadius.brSection,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => action.onTap(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSection,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AiCircleIcon(
                  icon: action.icon,
                  background: bg,
                  foreground: fg,
                  size: 44,
                ),
                AppSpacing.vGapSm,
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A recent AI activity entry, resolved to theme tokens by [tint].
class _Activity {
  const _Activity(this.icon, this.title, this.subtitle, this.time, this.tint);

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final _Tint tint;
}

/// The Recent Activity list: a header with "View All" over a card of history
/// rows (icon badge, title, subtitle, timestamp + chevron).
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final convsAsync = ref.watch(aiConversationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.ownerAiHistory),
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: const Text('View All'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        convsAsync.when(
          data: (convs) {
            if (convs.isEmpty) {
              return AppCard(
                backgroundColor: scheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'No recent AI activity recorded yet.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            final displayList = convs.take(3).toList();
            return AppCard(
              backgroundColor: scheme.surfaceContainerLowest,
              child: Column(
                children: [
                  for (var i = 0; i < displayList.length; i++) ...[
                    if (i > 0)
                      Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        height: AppSpacing.lg,
                      ),
                    _ActivityRow(
                      activity: _Activity(
                        Icons.chat_bubble_outline_rounded,
                        displayList[i].title,
                        'AI Consultation Thread',
                        '${displayList[i].updatedAt.hour}:${displayList[i].updatedAt.minute.toString().padLeft(2, '0')}',
                        _Tint.primary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => AppCard(
            backgroundColor: scheme.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Unable to load AI history.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, fg) = switch (activity.tint) {
      _Tint.primary => (
        scheme.primaryContainer.withValues(alpha: 0.2),
        scheme.primary,
      ),
      _Tint.secondary => (
        scheme.secondaryContainer.withValues(alpha: 0.2),
        scheme.secondary,
      ),
      _Tint.tertiary => (
        scheme.tertiaryContainer.withValues(alpha: 0.2),
        scheme.tertiary,
      ),
    };

    return AiListTile(
      leading: AiCircleIcon(
        icon: activity.icon,
        background: bg,
        foreground: fg,
      ),
      title: activity.title,
      subtitle: activity.subtitle,
      onTap: () => context.showSnackbar('Opening ${activity.title}…'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activity.time,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.outline,
            ),
          ),
          AppSpacing.hGapXs,
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.outlineVariant,
            size: AppIconSizes.md,
          ),
        ],
      ),
    );
  }
}
