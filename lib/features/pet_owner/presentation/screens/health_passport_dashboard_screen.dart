import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/health_widgets.dart';

/// **Health Passport Dashboard** — the `/owner/health` hub.
///
/// Frozen Stitch comp: a wellness-score gauge, an AI health insight, a
/// horizontal quick-action rail into the four sub-passports, a 2×2 stat grid,
/// a recent event and an article promo. Emerald in the comp maps to the Pet
/// Owner portal **accent**; every other color to the active [ColorScheme].
class HealthPassportDashboardScreen extends StatelessWidget {
  const HealthPassportDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(context, title: 'Health'),
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
              child: const _DashboardBody(),
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final accent = palette.accent;
    final onAccent = context.colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WellnessCard(
          accent: accent,
          onAccent: onAccent,
          container: palette.accentContainer(brightness),
          onContainer: palette.onAccentContainer(brightness),
        ),
        AppSpacing.vGapLg,
        _AiInsightCard(
          accent: accent,
          container: palette.accentContainer(brightness),
          onContainer: palette.onAccentContainer(brightness),
        ),
        AppSpacing.vGapLg,
        _QuickActionRail(accent: accent),
        AppSpacing.vGapLg,
        const _StatGrid(),
        AppSpacing.vGapLg,
        const _RecentEventCard(),
        AppSpacing.vGapLg,
        const _ArticleCard(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wellness score
// ═══════════════════════════════════════════════════════════════════

class _WellnessCard extends StatelessWidget {
  const _WellnessCard({
    required this.accent,
    required this.onAccent,
    required this.container,
    required this.onContainer,
  });

  final Color accent;
  final Color onAccent;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Overall Wellness Score',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapLg,
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _WellnessGaugePainter(
                progress: 0.92,
                track: scheme.outlineVariant.withValues(alpha: 0.4),
                accent: accent,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '92',
                      style: context.textTheme.displayMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.vGapLg,
          HealthCategoryChip(
            label: 'Optimal Health',
            icon: Icons.verified_rounded,
            background: container,
            foreground: onContainer,
          ),
          AppSpacing.vGapSm,
          Text(
            'Last updated 2 hours ago',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          HealthAccentButton(
            label: 'Share Milestone',
            icon: Icons.share_rounded,
            accent: accent,
            onAccent: onAccent,
            onPressed: () => context.showSnackbar('Sharing wellness milestone…'),
          ),
        ],
      ),
    );
  }
}

/// Paints the wellness ring: a full track plus an accent arc for [progress].
class _WellnessGaugePainter extends CustomPainter {
  const _WellnessGaugePainter({
    required this.progress,
    required this.track,
    required this.accent,
  });

  final double progress;
  final Color track;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [accent.withValues(alpha: 0.7), accent],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_WellnessGaugePainter old) =>
      old.progress != progress || old.accent != accent || old.track != track;
}

// ═══════════════════════════════════════════════════════════════════
// AI insight
// ═══════════════════════════════════════════════════════════════════

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.accent,
    required this.container,
    required this.onContainer,
  });

  final Color accent;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brSection,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            container.withValues(alpha: 0.6),
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HealthCircleIcon(
                icon: Icons.auto_awesome_rounded,
                background: container,
                foreground: onContainer,
                size: 40,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Weight Stability',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
              HealthCategoryChip(
                label: '98% Match',
                background: container,
                foreground: onContainer,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            "Buddy's weight has stabilized at 65lbs. AI suggests current "
            'nutrition plan is optimal.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick actions
// ═══════════════════════════════════════════════════════════════════

class _QuickActionRail extends StatelessWidget {
  const _QuickActionRail({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        Icons.vaccines_rounded,
        'Vaccines',
        () => context.goNamed(RouteNames.ownerHealthVaccinations),
      ),
      _QuickAction(
        Icons.history_rounded,
        'History',
        () => context.goNamed(RouteNames.ownerHealthMedical),
      ),
      _QuickAction(
        Icons.monitor_weight_rounded,
        'Weight',
        () => context.goNamed(RouteNames.ownerHealthGrowth),
      ),
      _QuickAction(
        Icons.medication_rounded,
        'Meds',
        () => context.goNamed(RouteNames.ownerHealthMedical),
      ),
      _QuickAction(
        Icons.biotech_rounded,
        'Lab Reports',
        () => context.goNamed(RouteNames.ownerHealthMedical),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Quick Actions',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (_, i) =>
                _QuickActionTile(action: actions[i], accent: accent),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.accent});

  final _QuickAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: 80,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: AppRadius.brCard,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(action.icon, color: accent, size: AppIconSizes.md),
            ),
            AppSpacing.vGapXs,
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Stat grid
// ═══════════════════════════════════════════════════════════════════

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    const stats = [
      _Stat(Icons.vaccines_rounded, 'Vaccinations', 'Up to date'),
      _Stat(Icons.event_rounded, 'Next Appt', 'Oct 12'),
      _Stat(Icons.monitor_weight_rounded, 'Weight', '65 lbs'),
      _Stat(Icons.medication_rounded, 'Medication', '1 Active'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final s in stats) _StatTile(stat: s)],
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: scheme.primary, size: AppIconSizes.sm),
          AppSpacing.vGapXs,
          Text(
            stat.label,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            stat.value,
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent event + article
// ═══════════════════════════════════════════════════════════════════

class _RecentEventCard extends StatelessWidget {
  const _RecentEventCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Recent Event',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          onTap: () => context.goNamed(RouteNames.ownerHealthTimeline),
          child: HealthRecordRow(
            leading: HealthCircleIcon(
              icon: Icons.vaccines_rounded,
              background: scheme.secondaryContainer,
              foreground: scheme.onSecondaryContainer,
            ),
            title: 'Annual Rabies Booster',
            meta: const [HealthMetaLine('Administered by Dr. Smith')],
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Row(
        children: [
          HealthCircleIcon(
            icon: Icons.menu_book_rounded,
            background: scheme.tertiaryContainer,
            foreground: scheme.onTertiaryContainer,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintaining Senior Dog Vitality',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  'Health Hub article',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          TextButton(
            onPressed: () => context.showSnackbar('Opening Health Hub…'),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: const Text('View Hub'),
          ),
        ],
      ),
    );
  }
}
