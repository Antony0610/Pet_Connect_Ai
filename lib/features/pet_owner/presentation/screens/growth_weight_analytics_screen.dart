import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/health_widgets.dart';

/// **Growth & Weight Analytics** — `/owner/health/growth`.
///
/// Frozen Stitch comp: a current-weight hero with an AI verdict, a growth
/// curve line chart with a range segmented control, a body-condition meter and
/// a recent weigh-ins list. The chart and meter are custom-painted (no chart
/// package in the project). Emerald maps to the Pet Owner accent.
class GrowthWeightAnalyticsScreen extends StatefulWidget {
  const GrowthWeightAnalyticsScreen({super.key});

  @override
  State<GrowthWeightAnalyticsScreen> createState() =>
      _GrowthWeightAnalyticsScreenState();
}

class _GrowthWeightAnalyticsScreenState
    extends State<GrowthWeightAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(context, title: 'Growth & Weight'),
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
                  _CurrentWeightCard(
                    accent: palette.accent,
                    container: palette.accentContainer(brightness),
                    onContainer: palette.onAccentContainer(brightness),
                  ),
                  AppSpacing.vGapLg,
                  _GrowthCurveCard(accent: palette.accent),
                  AppSpacing.vGapLg,
                  _BodyConditionCard(
                    accent: palette.accent,
                    onAccent: scheme.onPrimary,
                  ),
                  AppSpacing.vGapLg,
                  const _RecentWeighIns(),
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

class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({
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

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Weight',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '65',
                style: context.textTheme.displaySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.hGapXs,
              Text(
                'lbs',
                style: context.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.hGapSm,
              HealthCategoryChip(
                label: '0.5 lb',
                icon: Icons.arrow_downward_rounded,
                background: container,
                foreground: onContainer,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: AppRadius.brCard,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smart_toy_rounded, color: accent, size: AppIconSizes.sm),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Buddy is in the ideal range for a Golden Retriever.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════
// Growth curve
// ═══════════════════════════════════════════════════════════════════

class _GrowthCurveCard extends StatefulWidget {
  const _GrowthCurveCard({required this.accent});

  final Color accent;

  @override
  State<_GrowthCurveCard> createState() => _GrowthCurveCardState();
}

class _GrowthCurveCardState extends State<_GrowthCurveCard> {
  static const _ranges = ['3M', '6M', '1Y', 'All'];
  int _range = 0;

  // Seed weigh-in series from the frozen comp (lbs).
  static const _series = <double>[64.2, 64.6, 64.4, 65.1, 65.5, 65.0];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Growth Curve',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          _RangeSelector(
            ranges: _ranges,
            selected: _range,
            accent: widget.accent,
            onChanged: (i) => setState(() => _range = i),
          ),
          AppSpacing.vGapLg,
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                values: _series,
                line: widget.accent,
                fill: widget.accent.withValues(alpha: 0.15),
                grid: scheme.outlineVariant.withValues(alpha: 0.4),
                dot: widget.accent,
                dotBorder: scheme.surface,
              ),
            ),
          ),
          AppSpacing.vGapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['Aug', 'Sep', 'Oct'])
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.ranges,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final List<String> ranges;
  final int selected;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.brPill,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          for (var i = 0; i < ranges.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: i == selected ? accent : Colors.transparent,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    ranges[i],
                    style: context.textTheme.labelLarge?.copyWith(
                      color: i == selected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints a smooth weight line with a soft gradient fill, grid baselines and
/// endpoint dots. Values are auto-scaled to the min/max of the series.
class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.dot,
    required this.dotBorder,
  });

  final List<double> values;
  final Color line;
  final Color fill;
  final Color grid;
  final Color dot;
  final Color dotBorder;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    const pad = 12.0;

    Offset pointAt(int i) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final norm = (values[i] - minV) / span;
      final y = size.height - pad - norm * (size.height - pad * 2);
      return Offset(x, y);
    }

    final points = [for (var i = 0; i < values.length; i++) pointAt(i)];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, fill.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 6, Paint()..color = dotBorder);
    canvas.drawCircle(last, 4, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.line != line || old.fill != fill;
}
// ═══════════════════════════════════════════════════════════════════
// Body condition
// ═══════════════════════════════════════════════════════════════════

class _BodyConditionCard extends StatelessWidget {
  const _BodyConditionCard({required this.accent, required this.onAccent});

  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Condition',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Score 5 of 9 — visual & touch assessment',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          _ConditionMeter(
            accent: accent,
            onAccent: onAccent,
            under: scheme.tertiaryContainer,
            over: scheme.errorContainer,
          ),
          AppSpacing.vGapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['Underweight', 'Ideal', 'Overweight'])
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          AppSpacing.vGapLg,
          AppButton(
            label: 'Log New Photo Assessment',
            icon: Icons.add_a_photo_rounded,
            variant: AppButtonVariant.tonal,
            isFullWidth: true,
            onPressed: () =>
                context.showSnackbar('Opening photo assessment…'),
          ),
        ],
      ),
    );
  }
}

class _ConditionMeter extends StatelessWidget {
  const _ConditionMeter({
    required this.accent,
    required this.onAccent,
    required this.under,
    required this.over,
  });

  final Color accent;
  final Color onAccent;
  final Color under;
  final Color over;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const pinFraction = 0.5; // "Ideal (5)" sits mid-scale.

        return SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _seg(under)),
                      Expanded(flex: 4, child: _seg(accent)),
                      Expanded(flex: 3, child: _seg(over)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (width * pinFraction) - 28,
                top: 0,
                child: HealthCategoryChip(
                  label: 'Ideal (5)',
                  background: accent,
                  foreground: onAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _seg(Color color) => Container(height: 12, color: color);
}

// ═══════════════════════════════════════════════════════════════════
// Recent weigh-ins
// ═══════════════════════════════════════════════════════════════════

class _RecentWeighIns extends StatelessWidget {
  const _RecentWeighIns();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final entries = <_WeighIn>[
      _WeighIn('65.0 lbs', 'Oct 24, 2023', Icons.home_rounded),
      _WeighIn('65.5 lbs', 'Sep 15, 2023', Icons.local_hospital_rounded),
      _WeighIn('64.2 lbs', 'Aug 02, 2023', Icons.home_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Recent Weigh-ins',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(color: scheme.outlineVariant, height: AppSpacing.lg),
                HealthRecordRow(
                  leading: HealthCircleIcon(
                    icon: entries[i].icon,
                    background: scheme.surfaceContainerHigh,
                    foreground: scheme.onSurfaceVariant,
                  ),
                  title: entries[i].weight,
                  meta: [HealthMetaLine(entries[i].date)],
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        AppSpacing.vGapSm,
        Center(
          child: TextButton(
            onPressed: () => context.showSnackbar('Opening full history…'),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: const Text('View All History'),
          ),
        ),
      ],
    );
  }
}

class _WeighIn {
  const _WeighIn(this.weight, this.date, this.icon);
  final String weight;
  final String date;
  final IconData icon;
}
