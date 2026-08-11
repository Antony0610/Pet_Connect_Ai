import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Rescue History Screen (Stitch ID: `a978dd78e811493d9f8a4274bed18b5f`).
///
/// Historical operations log & impact analytics screen. Displays AI mission insights banner,
/// status filter tabs, and historical rescue incident cards.
class RescueHistoryScreen extends StatefulWidget {
  const RescueHistoryScreen({super.key});

  @override
  State<RescueHistoryScreen> createState() => _RescueHistoryScreenState();
}

class _RescueHistoryScreenState extends State<RescueHistoryScreen> {
  String _selectedStatus = 'All';

  final List<Map<String, dynamic>> _historyItems = [
    {
      'date': 'Oct 24 • 14:30',
      'title': 'Luna - Siberian Husky',
      'location': 'Pine Ridge Trail, Sector 4',
      'duration': '42 mins',
      'distance': '1.2 mi',
      'status': 'Success',
      'statusColor': AppColors.success,
    },
    {
      'date': 'Oct 18 • 09:15',
      'title': 'Stray Golden Retriever',
      'location': 'Route 42, near old barn',
      'duration': '1h 15m',
      'distance': '3.4 mi',
      'status': 'Resolved',
      'statusColor': AppColors.info,
    },
    {
      'date': 'Oct 10 • 18:40',
      'title': 'Trapped Feline in Drainage',
      'location': 'Main St & 8th Ave Culvert',
      'duration': '2h 05m',
      'distance': '0.5 mi',
      'status': 'Escalated',
      'statusColor': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue History & Impact Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AI Mission Insights Banner ───────────────────────
                _buildAiInsightsBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Filter Chips ────────────────────────────────────
                _buildFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── History Incident Cards ──────────────────────────
                ..._historyItems.map(
                  (item) =>
                      _buildHistoryCard(context, theme, colorScheme, item),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiInsightsBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 28),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Mission Impact Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: colorScheme.primary,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  "You've successfully completed 12 rescues this month, driving 45 miles. Average response time improved by 15% compared to last month!",
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

  Widget _buildFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final filters = ['All', 'Completed', 'Resolved', 'Escalated'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: f,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedStatus = f),
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              textColor: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> item,
  ) {
    final statusColor = item['statusColor'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item['date'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                AppChip(
                  label: item['status'] as String,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              item['title'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            Text(
              item['location'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${item['duration']}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                AppSpacing.hGapMd,
                Icon(
                  Icons.route_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Covered: ${item['distance']}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
