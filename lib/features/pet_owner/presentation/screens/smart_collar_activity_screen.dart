import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A single logged activity in the day's timeline.
class _Event {
  const _Event(this.icon, this.title, this.detail, this.time, this.tint);

  final IconData icon;
  final String title;
  final String detail;
  final String time;
  final _Tint tint;
}

/// Which container role tints a timeline event's leading glyph.
enum _Tint { primary, secondary, tertiary }

/// **Activity Monitoring** — `/owner/collar/activity`.
///
/// The collar's daily activity summary: a goal ring, a stat grid (steps,
/// distance, active minutes, rest) and a time-stamped daily timeline. Composes
/// the frozen collar primitives; token-driven, one tree for both themes.
class SmartCollarActivityScreen extends StatelessWidget {
  const SmartCollarActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final isWide = width >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(
        context,
        title: 'Activity',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Change day',
            onPressed: () => context.showSnackbar('Pick a day…'),
          ),
        ],
      ),
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
                  const _GoalHero(),
                  AppSpacing.vGapMd,
                  _StatGrid(isWide: isWide),
                  AppSpacing.vGapLg,
                  Text(
                    "Today's Timeline",
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  const _Timeline(),
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

// __CONT_1__
/// The daily-goal hero: the step ring beside a short "goal progress" readout.
class _GoalHero extends StatelessWidget {
  const _GoalHero();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final readout = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Daily Goal',
          style: context.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          '6,540 of 10,000 steps — Buddy is 65% of the way to today’s goal '
          'with plenty of daylight left.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final ring = CollarMetricRing(
      progress: 0.65,
      arcColor: scheme.primary,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '65%',
            style: context.textTheme.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.bold,
              height: 1,
            ),
          ),
          Text(
            'of goal',
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return AppCard(
      child: context.screenWidth >= AppBreakpoints.tablet
          ? Row(
              children: [
                ring,
                AppSpacing.hGapLg,
                Expanded(child: readout),
              ],
            )
          : Column(children: [ring, AppSpacing.vGapMd, readout]),
    );
  }
}

/// One headline activity metric.
class _Stat {
  const _Stat(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// A responsive grid of the day's headline activity metrics.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    const stats = [
      _Stat(Icons.pets_rounded, 'Steps', '6,540'),
      _Stat(Icons.straighten_rounded, 'Distance', '4.3 km'),
      _Stat(Icons.bolt_rounded, 'Active', '82 min'),
      _Stat(Icons.bedtime_rounded, 'Rest', '5.1 hrs'),
    ];

    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        for (final s in stats)
          CollarStatTile(icon: s.icon, label: s.label, value: s.value),
      ],
    );
  }
}

/// The time-stamped list of the day's logged activity events.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    const events = [
      _Event(
        Icons.directions_walk_rounded,
        'Morning walk',
        '2.1 km around Centennial Park',
        '7:30 AM',
        _Tint.primary,
      ),
      _Event(
        Icons.restaurant_rounded,
        'Breakfast logged',
        'Portion matched to activity plan',
        '8:15 AM',
        _Tint.secondary,
      ),
      _Event(
        Icons.sports_baseball_rounded,
        'Play session',
        'High activity — 20 active minutes',
        '11:40 AM',
        _Tint.tertiary,
      ),
      _Event(
        Icons.bedtime_rounded,
        'Afternoon rest',
        'Settled nap, steady heart rate',
        '2:05 PM',
        _Tint.secondary,
      ),
    ];

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0)
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                height: AppSpacing.lg,
              ),
            _EventRow(event: events[i]),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final _Event event;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, fg) = switch (event.tint) {
      _Tint.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tint.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _Tint.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(event.icon, color: fg, size: AppIconSizes.md),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: context.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              AppSpacing.vGapXs,
              Text(
                event.detail,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        Text(
          event.time,
          style: context.textTheme.labelMedium?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}
