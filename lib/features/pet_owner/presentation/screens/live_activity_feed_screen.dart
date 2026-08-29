import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// Live Activity Feed backed by real realtime ecosystem telemetry.
class LiveActivityFeedScreen extends ConsumerStatefulWidget {
  const LiveActivityFeedScreen({super.key});

  @override
  ConsumerState<LiveActivityFeedScreen> createState() =>
      _LiveActivityFeedScreenState();
}

class _LiveActivityFeedScreenState extends ConsumerState<LiveActivityFeedScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'System',
    'Community',
    'AI Health',
    'Alerts',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final notifs = ref.watch(userNotificationsProvider).valueOrNull ?? [];
    final posts = ref.watch(communityPostsProvider(null)).valueOrNull ?? [];
    final scans = ref.watch(aiHealthScansProvider).valueOrNull ?? [];
    final lostAlerts = ref.watch(activeLostPetAlertsProvider).valueOrNull ?? <LostPetAlert>[];

    final logs = <_ActivityLogItem>[];

    // 1. Synthesize real notifications
    for (final n in notifs) {
      final isCollar = n.notificationType.toUpperCase().contains('COLLAR') ||
          n.notificationType.toUpperCase().contains('BATTERY');
      final isAi = n.notificationType.toUpperCase().contains('AI');

      logs.add(
        _ActivityLogItem(
          date: n.createdAt,
          category: isCollar ? 'Alerts' : (isAi ? 'AI Health' : 'System'),
          title: n.title,
          subtitle: n.body,
          icon: isCollar
              ? Icons.warning_amber_rounded
              : (isAi ? Icons.psychology : Icons.notifications_active),
        ),
      );
    }

    // 2. Synthesize real community posts
    for (final p in posts) {
      logs.add(
        _ActivityLogItem(
          date: p.createdAt,
          category: 'Community',
          title: p.title,
          subtitle: p.content,
          icon: Icons.forum_rounded,
        ),
      );
    }

    // 3. Synthesize real AI health scans
    for (final s in scans) {
      logs.add(
        _ActivityLogItem(
          date: s.createdAt,
          category: 'AI Health',
          title: 'AI Symptom Triage (${s.urgencyLevel})',
          subtitle: s.analysisSummary,
          icon: Icons.health_and_safety_rounded,
        ),
      );
    }

    // 4. Synthesize real lost pet alerts
    for (final a in lostAlerts) {
      logs.add(
        _ActivityLogItem(
          date: a.createdAt,
          category: 'Alerts',
          title: 'Lost Pet Alert (Active)',
          subtitle: 'Last seen near ${a.lastSeenLocation}.${a.contactPhone != null ? " Contact: ${a.contactPhone}" : ""}',
          icon: Icons.campaign_rounded,
        ),
      );
    }

    // Sort chronologically (newest first)
    logs.sort((a, b) => b.date.compareTo(a.date));

    final filteredLogs = _selectedFilter == 'All'
        ? logs
        : logs.where((l) => l.category == _selectedFilter).toList();

    final activeLostAlert = lostAlerts.isNotEmpty ? lostAlerts.first : null;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Filter Chips Row ──────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Critical Emergency Banner (Only shown if real alert exists!) ─
                if (activeLostAlert != null) ...[
                  AiGradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Active Community Alert',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: scheme.error,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Active Community Search Alert',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          'Last seen: ${activeLostAlert.lastSeenLocation}',
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
                ],

                // ── Activity Stream Logs ───────────────────────────
                const SectionHeader(title: 'Live Stream Activity'),
                AppSpacing.vGapSm,
                if (filteredLogs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.stream_rounded, size: 40, color: scheme.onSurfaceVariant),
                        AppSpacing.vGapSm,
                        Text(
                          'No live activity logged yet.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredLogs.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        item.formattedTime,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall?.copyWith(
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
    required this.date,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final DateTime date;
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
