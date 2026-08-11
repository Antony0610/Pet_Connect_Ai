import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class ClinicAnalyticsScreen extends StatelessWidget {
  const ClinicAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                const SnackBar(content: Text('Exporting Analytics Report...')),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary Box
              _buildAnalyticsHeader(context, theme, colorScheme),
              const SizedBox(height: 16),

              // KPI Performance Cards Row
              _buildKpiRow(context, theme, colorScheme),
              const SizedBox(height: 20),

              // AI Optimization Insight Card
              _buildAiInsightCard(context, theme, colorScheme),
              const SizedBox(height: 20),

              // Treatment Outcomes Chart Card
              _buildOutcomesChartCard(context, theme, colorScheme),
              const SizedBox(height: 20),

              // Vaccination Trends Breakdown Card
              _buildVaccineTrendsCard(context, theme, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oakridge Practice Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          AppButton(
            text: 'Export',
            onPressed: () {},
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: 'Patient Growth',
            value: '1,248',
            sub: '+15% this month',
            color: colorScheme.primary,
            badge: '+15%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: 'Avg. Consult',
            value: '18m',
            sub: '-2m vs last month',
            color: colorScheme.secondary,
            badge: '-2m',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: 'Satisfaction',
            value: '4.8 / 5',
            sub: '342 reviews',
            color: AppColors.warning,
            badge: 'Top 5%',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required String sub,
    required Color color,
    required String badge,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(12),
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

  Widget _buildAiInsightCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
          const SizedBox(width: 10),
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
                  'Vaccination appointments are trending 20% higher than historical averages for Q2. Consider reallocating schedule blocks to accommodate demand.',
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

  Widget _buildOutcomesChartCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Treatment Outcomes (Success Rate)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppChip(
                label: '96% Overall',
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                textColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Visual Placeholder Bars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(context, colorScheme, 'Jan', 0.6),
              _buildBar(context, colorScheme, 'Feb', 0.8),
              _buildBar(context, colorScheme, 'Mar', 0.7),
              _buildBar(context, colorScheme, 'Apr', 0.95),
              _buildBar(context, colorScheme, 'May', 0.85),
              _buildBar(context, colorScheme, 'Jun', 0.9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    ColorScheme colorScheme,
    String month,
    double factor,
  ) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 100 * factor,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildVaccineTrendsCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vaccination Distribution Trends',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTrendRow(
            context,
            'Rabies',
            '340 doses',
            0.85,
            colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildTrendRow(
            context,
            'DHPP',
            '215 doses',
            0.60,
            colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          _buildTrendRow(
            context,
            'Bordetella',
            '180 doses',
            0.45,
            colorScheme.tertiary,
          ),
          const SizedBox(height: 8),
          _buildTrendRow(context, 'FVRCP', '120 doses', 0.30, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildTrendRow(
    BuildContext context,
    String label,
    String count,
    double factor,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              count,
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
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
