import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/cards/glass_card.dart';

/// The Pet Owner **Pet Profile Detail** screen.
///
/// A faithful Flutter rendering of the frozen Stitch "Pet Profile Detail"
/// (Light master): a glass header, a hero photo with a gradient fade, an
/// overlapping glass pet-info card (name / breed / age / weight), a six-slot
/// quick-actions grid and a bento of personality, activity level and timeline
/// preview cards. Every color, spacing, radius, type and elevation comes from
/// the theme / design tokens so one widget tree serves both Light and Dark.
///
/// Reached from the "My Pets" list with a `petId` path parameter; the design
/// comp is rendered for the featured pet ("Bella").
class PetProfileDetailScreen extends StatelessWidget {
  const PetProfileDetailScreen({super.key});

  static const String _heroPhotoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBGFV_pbjsU4U9lQQlVb4lf8p6GQm10sWarSnNaGQGtjicsgw8LVzLV7QpWOf-KGYW3l1aArnjMBekTnWbCEq9XRjz0xBVmeCcuPdRQ4Ds38Cfswj6c5xxTQYP6S_q0h3rGWiElYbKZ38w-jJwdbRPrarYLGUlDgHWzjiyCA2GeA9c2P4324UWuP4q69-a6PEJIAPB8H-y76ICEqHg0f54akaEvC3OWdAkYv83E_YBhcn67k6FER6BtVQ';

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final width = context.screenWidth;
    final isWide = AppBreakpoints.isDesktop(width);
    final margin = _horizontalMargin(width);

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Text(
        'PetConnect AI',
        style: context.textTheme.headlineSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: AppTypography.bold,
          letterSpacing: -0.25,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero photo ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    topPad + AppSpacing.md,
                    margin,
                    0,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.brCard,
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: isWide ? 21 / 9 : 4 / 3,
                          child: Image.network(
                            _heroPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _HeroFallback(wide: isWide),
                          ),
                        ),
                        if (!isWide)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    context.colorScheme.surface.withValues(
                                      alpha: 0,
                                    ),
                                    context.colorScheme.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ── Overlapping pet info card ───────────────────────────
                Transform.translate(
                  offset: Offset(0, isWide ? 0 : -AppSpacing.xl),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? margin : AppSpacing.sm,
                    ),
                    child: _PetInfoCard(palette: palette),
                  ),
                ),
                if (!isWide)
                  const SizedBox(height: AppSpacing.xl - AppSpacing.sm),
                // ── Quick Actions ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    isWide ? AppSpacing.xl : AppSpacing.sm,
                    margin,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: context.textTheme.headlineSmall,
                      ),
                      AppSpacing.vGapMd,
                      _QuickActionsGrid(wide: isWide),
                    ],
                  ),
                ),
                // ── Bento details ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    AppSpacing.xl,
                    margin,
                    0,
                  ),
                  child: isWide
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _PersonalityActivityColumn()),
                            AppSpacing.hGapMd,
                            Expanded(flex: 2, child: _TimelinePreviewCard()),
                          ],
                        )
                      : const _PersonalityActivityColumn(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
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

/// Glass info card overlapping the hero: name / breed + age / weight stats.
class _PetInfoCard extends StatelessWidget {
  const _PetInfoCard({required this.palette});

  final PortalPalette palette;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: AppSpacing.cardPaddingPremium,
      borderRadius: AppRadius.brCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bella',
                style: context.textTheme.headlineLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
              Text(
                'Golden Retriever',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              _PetStatBox(label: 'Age', value: '3y'),
              AppSpacing.hGapSm,
              _PetStatBox(label: 'Weight', value: '65lb'),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact stat tile (Age / Weight) inside the pet info card.
class _PetStatBox extends StatelessWidget {
  const _PetStatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          RichText(
            text: TextSpan(
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: AppTypography.semiBold,
              ),
              children: [TextSpan(text: value)],
            ),
          ),
          if (value.endsWith('lb'))
            Text(
              'lb',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The six-slot quick-actions grid (3 across on mobile, 6 across on desktop).
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(
        label: 'Health',
        icon: Icons.favorite,
        iconFilled: true,
        background: context.colorScheme.primaryContainer.withValues(
          alpha: 0.10,
        ),
        color: context.colorScheme.primary,
        onTap: () => context.goNamed(RouteNames.ownerHealth),
      ),
      _QuickAction(
        label: 'AI',
        icon: Icons.smart_toy,
        iconFilled: true,
        background: Color.alphaBlend(
          context.colorScheme.secondaryContainer.withValues(alpha: 0.35),
          context.colorScheme.primaryContainer.withValues(alpha: 0.25),
        ),
        color: context.colorScheme.primary,
        onTap: () => context.goNamed(RouteNames.ownerAiAssistant),
      ),
      _QuickAction(
        label: 'Collar',
        icon: Icons.pets,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () => context.goNamed(RouteNames.ownerCollar),
      ),
      _QuickAction(
        label: 'Appts',
        icon: Icons.event,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
      ),
      _QuickAction(
        label: 'Lost',
        icon: Icons.location_on,
        background: context.colorScheme.errorContainer.withValues(alpha: 0.20),
        color: context.colorScheme.error,
        onTap: () => context.goNamed(RouteNames.ownerLostMode),
      ),
      _QuickAction(
        label: 'Community',
        icon: Icons.groups,
        background: context.colorScheme.surfaceContainer,
        color: context.colorScheme.onSurfaceVariant,
        onTap: () => context.goNamed(RouteNames.ownerCommunity),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 6 : 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

/// A single quick-action tile.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.color,
    this.iconFilled = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color color;
  final bool iconFilled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppIconSizes.lg,
              color: color,
              fill: iconFilled ? 1 : 0,
            ),
            AppSpacing.vGapXs,
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento left column: personality tags + activity level card.
class _PersonalityActivityColumn extends StatelessWidget {
  const _PersonalityActivityColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PersonalityCard(),
        AppSpacing.vGapMd,
        const _ActivityLevelCard(),
        if (!AppBreakpoints.isDesktop(context.screenWidth)) ...[
          AppSpacing.vGapMd,
          const _TimelinePreviewCard(),
        ],
      ],
    );
  }
}

/// Personality tags card.
class _PersonalityCard extends StatelessWidget {
  const _PersonalityCard();

  @override
  Widget build(BuildContext context) {
    final tags = ['Friendly', 'Energetic', 'Food Motivated'];
    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: AppIconSizes.md,
                color: context.colorScheme.secondary,
              ),
              AppSpacing.hGapSm,
              Text(
                'Personality',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      tag,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Activity level card with a tertiary progress bar.
class _ActivityLevelCard extends StatelessWidget {
  const _ActivityLevelCard();

  @override
  Widget build(BuildContext context) {
    final tertiary = context.colorScheme.tertiary;
    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: AppIconSizes.md, color: tertiary),
                  AppSpacing.hGapSm,
                  Text(
                    'Activity Level',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ],
              ),
              Text(
                'High',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: tertiary,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: 0.85,
              minHeight: AppSpacing.xs,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(tertiary),
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Requires 2+ hours of exercise daily.',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timeline preview card (two-column span on desktop).
class _TimelinePreviewCard extends StatelessWidget {
  const _TimelinePreviewCard();

  @override
  Widget build(BuildContext context) {
    final entries = <_TimelineEntry>[
      _TimelineEntry(
        icon: Icons.vaccines,
        iconBackground: context.colorScheme.primaryContainer,
        iconColor: context.colorScheme.onPrimaryContainer,
        title: 'Annual Checkup & Vaccines',
        subtitle: 'Dr. Smith Veterinary Clinic',
        date: 'Oct 12',
      ),
      _TimelineEntry(
        icon: Icons.directions_walk,
        iconBackground: context.colorScheme.secondaryContainer,
        iconColor: context.colorScheme.onSecondaryContainer,
        title: 'Park Visit',
        subtitle: 'Central Bark Park',
        date: 'Oct 10',
      ),
      _TimelineEntry(
        icon: Icons.restaurant,
        iconBackground: context.colorScheme.tertiaryContainer,
        iconColor: context.colorScheme.onTertiaryContainer,
        title: 'Switched to Adult Food',
        subtitle: 'Premium Kibble Brand',
        date: 'Sep 28',
      ),
    ];

    return AppCard(
      padding: AppSpacing.cardPaddingPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline Preview',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: entry.iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.icon,
                      size: AppIconSizes.sm,
                      color: entry.iconColor,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        Text(
                          entry.subtitle,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entry.date,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String date;
}

/// Placeholder shown while the hero photo streams in (or fails to load).
class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 320 : 256,
      color: context.colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.pets,
        size: AppIconSizes.xxl,
        color: context.colorScheme.primary.withValues(alpha: 0.35),
      ),
    );
  }
}
