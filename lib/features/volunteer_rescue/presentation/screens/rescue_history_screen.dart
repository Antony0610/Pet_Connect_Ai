import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// **Rescue History Screen** — `/rescue/history`.
///
/// Historical operations log & impact analytics screen. Displays AI mission insights banner,
/// status filter tabs, search filter, and exportable rescue mission debriefs.
class RescueHistoryScreen extends StatefulWidget {
  const RescueHistoryScreen({super.key});

  @override
  State<RescueHistoryScreen> createState() => _RescueHistoryScreenState();
}

class _RescueHistoryScreenState extends State<RescueHistoryScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _historyItems = [
    {
      'date': 'Oct 24 • 14:30',
      'title': 'Luna - Siberian Husky',
      'location': 'Pine Ridge Trail, Sector 4',
      'duration': '42 mins',
      'distance': '1.2 mi',
      'status': 'Success',
      'statusColor': AppColors.success,
      'notes': 'Reunited with owner safely. No acute clinical injuries detected.',
    },
    {
      'date': 'Oct 18 • 09:15',
      'title': 'Stray Golden Retriever',
      'location': 'Route 42, near old barn',
      'duration': '1h 15m',
      'distance': '3.4 mi',
      'status': 'Resolved',
      'statusColor': AppColors.info,
      'notes': 'Transferred to Oakridge Animal Shelter for health screening & foster.',
    },
    {
      'date': 'Oct 10 • 18:40',
      'title': 'Trapped Feline in Drainage',
      'location': 'Main St & 8th Ave Culvert',
      'duration': '2h 05m',
      'distance': '0.5 mi',
      'status': 'Escalated',
      'statusColor': AppColors.warning,
      'notes': 'Municipal animal control dispatched with specialized hydraulic hoist.',
    },
    {
      'date': 'Sep 28 • 11:20',
      'title': 'Milo - Beagle Mix',
      'location': 'East Lake Recreation Park',
      'duration': '35 mins',
      'distance': '0.8 mi',
      'status': 'Success',
      'statusColor': AppColors.success,
      'notes': 'Collar beacon tracked within 50m. Owner notified on site.',
    },
  ];

  void _exportHistoryReport() {
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('     OFFICIAL VOLUNTEER RESCUE MISSION ARCHIVE      ');
    buffer.writeln('          PetConnect AI Emergency Response          ');
    buffer.writeln('====================================================');
    buffer.writeln('Export Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Operations Logged: ${_historyItems.length}');
    buffer.writeln();

    for (final item in _historyItems) {
      buffer.writeln('• ${item['title']} (${item['date']})');
      buffer.writeln('  Location: ${item['location']}');
      buffer.writeln('  Outcome:  ${item['status']} | Duration: ${item['duration']}');
      buffer.writeln('  Notes:    ${item['notes']}');
      buffer.writeln();
    }

    buffer.writeln('====================================================');
    buffer.writeln('Verified by PetConnect AI Volunteer Network         ');
    buffer.writeln('====================================================');

    ExternalActions.shareText(
      buffer.toString(),
      subject: 'PetConnect AI Rescue Operations Archive',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _historyItems.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'All' || item['status'] == _selectedStatus;

      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue History & Impact Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/rescue');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Rescue Report',
            onPressed: _exportHistoryReport,
          ),
        ],
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

                // ── Search & Filter Controls ─────────────────────────
                AppTextField(
                  hintText: 'Search past rescues by pet name or location…',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                AppSpacing.vGapSm,
                _buildFilterChips(theme, colorScheme),
                AppSpacing.vGapMd,

                // ── History Incident Cards ──────────────────────────
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No rescue missions match your criteria.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (item) => _buildHistoryCard(context, theme, colorScheme, item),
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 24),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations Impact Analysis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  'Your sector response team maintains a 94.2% successful recovery rate with an average response time of 38 minutes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
    final statuses = ['All', 'Success', 'Resolved', 'Escalated'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              selectedColor: colorScheme.primaryContainer,
              onSelected: (_) => setState(() => _selectedStatus = status),
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
    final statusColor = item['statusColor'] as Color? ?? Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['date'].toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    item['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              item['title'].toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            AppSpacing.vGapXs,
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                AppSpacing.hGapXs,
                Expanded(
                  child: Text(
                    item['location'].toString(),
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                item['notes']?.toString() ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
