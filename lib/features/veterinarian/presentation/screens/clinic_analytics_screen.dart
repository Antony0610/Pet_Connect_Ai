import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/clinic_analytics_summary.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

/// **Clinic Analytics** — `/vet/analytics` (Phase 11).
///
/// Reads live data from `vw_clinic_analytics` via [vetClinicAnalyticsProvider].
/// The backend enforces that only the clinic's owner / staff can read its data.
///
/// Timeframe selector aggregates monthly rows on the Flutter layer:
/// - "This Month" → current month row only
/// - "Last 3 Months" → sum of last 3 monthly rows
/// - "Last 6 Months" → sum of last 6 monthly rows
/// - "YTD" → sum of all rows in the current calendar year
///
/// Because the materialized view stores monthly granularity, sub-month
/// precision (e.g. exact "last 7 days") is not available and is not displayed.
class ClinicAnalyticsScreen extends ConsumerStatefulWidget {
  const ClinicAnalyticsScreen({super.key});

  @override
  ConsumerState<ClinicAnalyticsScreen> createState() =>
      _ClinicAnalyticsScreenState();
}

class _ClinicAnalyticsScreenState
    extends ConsumerState<ClinicAnalyticsScreen> {
  _Timeframe _selectedTimeframe = _Timeframe.thisMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Step 1: Resolve the vet's clinic from the existing provider.
    final clinicsAsync = ref.watch(vetClinicsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinic Analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Performance & Patient Metrics',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming in Phase 14.'),
                ),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SafeArea(
        child: clinicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: 'Could not load clinic information.',
            onRetry: () => ref.invalidate(vetClinicsProvider),
          ),
          data: (clinics) {
            if (clinics.isEmpty) {
              return const Center(
                child: Text('No clinic found for your account.'),
              );
            }
            final clinicId = clinics.first.id;
            return _AnalyticsBody(
              clinicId: clinicId,
              clinicName: clinics.first.name,
              selectedTimeframe: _selectedTimeframe,
              onTimeframeChanged: (tf) =>
                  setState(() => _selectedTimeframe = tf),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({
    required this.clinicId,
    required this.clinicName,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final String clinicId;
  final String clinicName;
  final _Timeframe selectedTimeframe;
  final ValueChanged<_Timeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analyticsAsync = ref.watch(vetClinicAnalyticsProvider(clinicId));

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: 'Could not load analytics data.',
        onRetry: () => ref.invalidate(vetClinicAnalyticsProvider(clinicId)),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _EmptyAnalytics(clinicName: clinicName);
        }
        final agg = _aggregate(rows, selectedTimeframe);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, colorScheme, clinicName),
              const SizedBox(height: AppSpacing.md),
              _buildTimeframeSelector(theme),
              const SizedBox(height: AppSpacing.md),
              _buildKpiRow(context, theme, colorScheme, agg),
              const SizedBox(height: AppSpacing.lg),
              _buildAiInsightCard(context, theme, colorScheme, agg),
              const SizedBox(height: AppSpacing.lg),
              _buildOutcomesCard(context, theme, colorScheme, rows),
              const SizedBox(height: AppSpacing.lg),
              _buildVaccineTrendsCard(context, theme, colorScheme, agg),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String name,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Comprehensive overview of patient & practice metrics.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            text: 'Refresh',
            onPressed: () {},
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(ThemeData theme) {
    return Row(
      children: _Timeframe.values.map((tf) {
        final selected = tf == selectedTimeframe;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: FilterChip(
            label: Text(tf.label),
            selected: selected,
            onSelected: (_) => onTimeframeChanged(tf),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    _AggregatedStats agg,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            theme: theme,
            colorScheme: colorScheme,
            title: 'Unique Patients',
            value: '${agg.uniquePatients}',
            sub: '${agg.totalAppointments} appts total',
            color: colorScheme.primary,
            badge: '${agg.completionRate.toStringAsFixed(0)}% done',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            theme: theme,
            colorScheme: colorScheme,
            title: 'Avg. Duration',
            value: '${agg.avgDuration.toStringAsFixed(0)}m',
            sub: 'per appointment',
            color: colorScheme.secondary,
            badge: '${agg.totalConsultations} consults',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            theme: theme,
            colorScheme: colorScheme,
            title: 'Prescriptions',
            value: '${agg.totalPrescriptions}',
            sub: '${agg.totalVaccinations} vaccinations',
            color: AppColors.warning,
            badge: '${agg.cancelledAppointments} cancelled',
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    _AggregatedStats agg,
  ) {
    final pct = agg.completionRate;
    final insight = pct >= 85
        ? 'Your completion rate of ${pct.toStringAsFixed(0)}% is excellent. '
            'Prescriptions (${agg.totalPrescriptions}) are well-matched to consultation volume.'
        : 'Completion rate is ${pct.toStringAsFixed(0)}%. '
            'Consider reviewing cancellation reasons to improve scheduling efficiency.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Schedule Optimization Insight',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomesCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<ClinicAnalyticsSummary> rows,
  ) {
    // Last 6 months of data for the bar chart
    final chartRows = rows.take(6).toList().reversed.toList();
    final maxAppts = chartRows
        .map((r) => r.totalAppointments)
        .fold(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appointment Volume by Month',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppChip(
                label:
                    '${chartRows.fold(0, (s, r) => s + r.totalAppointments)} total',
                backgroundColor:
                    AppColors.success.withValues(alpha: 0.15),
                textColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartRows.map((row) {
              final factor =
                  maxAppts > 0 ? row.totalAppointments / maxAppts : 0.0;
              final month =
                  '${row.reportMonth.month}/${row.reportMonth.year.toString().substring(2)}';
              return _Bar(
                colorScheme: colorScheme,
                label: month,
                factor: factor,
                count: row.totalAppointments,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineTrendsCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    _AggregatedStats agg,
  ) {
    // Display aggregate vaccination + consultation + prescription breakdown
    final items = [
      (
        'Consultations',
        agg.totalConsultations,
        agg.totalConsultations,
        colorScheme.primary,
      ),
      (
        'Prescriptions',
        agg.totalPrescriptions,
        agg.totalConsultations,
        colorScheme.secondary,
      ),
      (
        'Vaccinations',
        agg.totalVaccinations,
        agg.totalConsultations,
        colorScheme.tertiary,
      ),
    ];
    final maxVal =
        items.map((i) => i.$2).fold(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinical Activity Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) {
            final factor = maxVal > 0 ? item.$2 / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${item.$2}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: factor,
                    backgroundColor: item.$4.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(item.$4),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Aggregation ──────────────────────────────────────────────────────────

  _AggregatedStats _aggregate(
    List<ClinicAnalyticsSummary> rows,
    _Timeframe tf,
  ) {
    final now = DateTime.now();
    final filtered = rows.where((r) {
      return switch (tf) {
        _Timeframe.thisMonth =>
          r.reportMonth.year == now.year && r.reportMonth.month == now.month,
        _Timeframe.last3Months => r.reportMonth.isAfter(
            DateTime(now.year, now.month - 2, 1).subtract(
              const Duration(days: 1),
            ),
          ),
        _Timeframe.last6Months => r.reportMonth.isAfter(
            DateTime(now.year, now.month - 5, 1).subtract(
              const Duration(days: 1),
            ),
          ),
        _Timeframe.ytd => r.reportMonth.year == now.year,
      };
    }).toList();

    if (filtered.isEmpty) {
      return const _AggregatedStats.empty();
    }

    final totalApts = filtered.fold(0, (s, r) => s + r.totalAppointments);
    final completedApts =
        filtered.fold(0, (s, r) => s + r.completedAppointments);
    final cancelledApts =
        filtered.fold(0, (s, r) => s + r.cancelledAppointments);
    final avgDur = filtered.isNotEmpty
        ? filtered
                .map((r) => r.avgDurationMinutes)
                .reduce((a, b) => a + b) /
            filtered.length
        : 0.0;
    final totalConsults =
        filtered.fold(0, (s, r) => s + r.totalConsultations);
    final totalRx = filtered.fold(0, (s, r) => s + r.totalPrescriptions);
    final totalVax = filtered.fold(0, (s, r) => s + r.totalVaccinations);
    // Unique patients: max across months (not summed, since same patient
    // may appear multiple months)
    final uniquePts =
        filtered.map((r) => r.uniquePatients).fold(0, (a, b) => a > b ? a : b);

    return _AggregatedStats(
      totalAppointments: totalApts,
      completedAppointments: completedApts,
      cancelledAppointments: cancelledApts,
      avgDuration: avgDur,
      totalConsultations: totalConsults,
      totalPrescriptions: totalRx,
      totalVaccinations: totalVax,
      uniquePatients: uniquePts,
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.theme,
    required this.colorScheme,
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
    required this.badge,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final String title;
  final String value;
  final String sub;
  final Color color;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppChip(
                label: badge,
                backgroundColor: color.withValues(alpha: 0.15),
                textColor: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.colorScheme,
    required this.label,
    required this.factor,
    required this.count,
  });

  final ColorScheme colorScheme;
  final String label;
  final double factor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Container(
          width: 24,
          height: 80 * factor,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.clinicName});

  final String clinicName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 56, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No analytics data yet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Analytics will populate after appointments are completed.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

enum _Timeframe {
  thisMonth('This Month'),
  last3Months('3 Months'),
  last6Months('6 Months'),
  ytd('YTD');

  const _Timeframe(this.label);
  final String label;
}

class _AggregatedStats {
  const _AggregatedStats({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.avgDuration,
    required this.totalConsultations,
    required this.totalPrescriptions,
    required this.totalVaccinations,
    required this.uniquePatients,
  });

  const _AggregatedStats.empty()
    : totalAppointments = 0,
      completedAppointments = 0,
      cancelledAppointments = 0,
      avgDuration = 0,
      totalConsultations = 0,
      totalPrescriptions = 0,
      totalVaccinations = 0,
      uniquePatients = 0;

  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double avgDuration;
  final int totalConsultations;
  final int totalPrescriptions;
  final int totalVaccinations;
  final int uniquePatients;

  double get completionRate => totalAppointments > 0
      ? (completedAppointments / totalAppointments) * 100
      : 0;
}
