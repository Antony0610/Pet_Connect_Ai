import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Live Activity Feed**
/// (Light Theme design authority, ID `17a6b32e`).
///
/// Displays real-time social activity logs, critical emergency broadcasts,
/// AI analysis status logs, and volunteer dispatch updates.
class LiveActivityFeedScreen extends StatefulWidget {
  const LiveActivityFeedScreen({super.key});

  @override
  State<LiveActivityFeedScreen> createState() => _LiveActivityFeedScreenState();
}

class _LiveActivityFeedScreenState extends State<LiveActivityFeedScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'System',
    'Users',
    'Volunteers',
    'Emergencies',
  ];

  final List<_ActivityLogItem> _logs = const [
    _ActivityLogItem(
      timestamp: '10:42:01 AM',
      category: 'System',
      title: 'AI Health Analysis Completed for Luna',
      subtitle: 'Routine check processed successfully. No anomalies detected.',
      icon: Icons.psychology,
    ),
    _ActivityLogItem(
      timestamp: '10:35:14 AM',
      category: 'Volunteer',
      title: 'Rescue Mission Started by Sarah',
      subtitle: 'Mission #492 • En Route to location',
      icon: Icons.volunteer_activism,
    ),
    _ActivityLogItem(
      timestamp: '10:15:00 AM',
      category: 'User',
      title: 'New Registration in Seattle',
      subtitle: 'Onboarding completed. Added 2 pets.',
      icon: Icons.person_add_outlined,
    ),
    _ActivityLogItem(
      timestamp: '09:55:22 AM',
      category: 'System',
      title: 'Database Sync Completed',
      subtitle: 'Regional node update finished in 450ms.',
      icon: Icons.sync,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Live Activity Feed',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Filter Chips Row ──────────────────────────────
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Critical Emergency Banner ──────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: scheme.error,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'Critical Alerts • Requires Action',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Lost Mode Activated for Max',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Reported 2 mins ago in Downtown Area.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      AppButton.filled(
                        onPressed: () =>
                            context.goNamed(RouteNames.ownerCommunitySightings),
                        size: AppButtonSize.small,
                        child: const Text('View Alert Map'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Activity Stream Logs ───────────────────────────
                const SectionHeader(title: 'Live Stream Activity'),
                AppSpacing.vGapSm,
                ..._logs.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 18,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.category,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: AppTypography.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.timestamp,
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                                AppSpacing.vGapXs,
                                Text(
                                  item.title,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ActivityLogItem {
  const _ActivityLogItem({
    required this.timestamp,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String timestamp;
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
}
