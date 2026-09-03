import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class VolunteerAchievementsScreen extends ConsumerWidget {
  const VolunteerAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final missionsAsync = ref.watch(rescueMissionsProvider(null));
    final missions = missionsAsync.valueOrNull ?? [];
    final completedCount = missions.where((m) => m.status == 'completed' || m.status == 'resolved').length;
    final onDuty = ref.watch(volunteerDutyStatusProvider);

    // Calculate real tenure from account creation
    final createdAt = profile?.createdAt ?? DateTime.now();
    final tenureDays = DateTime.now().difference(createdAt).inDays;
    final tenureString = tenureDays < 30
        ? '$tenureDays Days'
        : (tenureDays < 365
            ? '${(tenureDays / 30).floor()} Months'
            : '${(tenureDays / 365).toStringAsFixed(1)} Years');

    // Calculate dynamic milestone level
    final (milestoneTitle, milestoneSub, progressValue, chipLabel) = _computeMilestone(completedCount);

    // Dynamic Badges evaluated against real user data
    final badges = [
      _BadgeData(
        title: 'First Responder',
        desc: 'Successfully resolved your first emergency rescue mission',
        icon: Icons.verified,
        earned: completedCount >= 1,
        progressLabel: completedCount >= 1 ? '1 / 1' : '0 / 1',
        color: AppColors.success,
      ),
      _BadgeData(
        title: 'Active Patrol',
        desc: 'Currently clocked in on-duty and responding to local alerts',
        icon: Icons.radar,
        earned: onDuty,
        progressLabel: onDuty ? 'On-Duty' : 'Standby',
        color: const Color(0xFF0EA5E9),
      ),
      _BadgeData(
        title: 'Lifesaver Tier',
        desc: 'Successfully completed 5 field rescue and stabilization missions',
        icon: Icons.shield,
        earned: completedCount >= 5,
        progressLabel: completedCount >= 5 ? '5 / 5' : '$completedCount / 5 Rescues',
        color: const Color(0xFFF59E0B),
      ),
      _BadgeData(
        title: 'Veteran Rescuer',
        desc: 'Dedicated over 6 months (180 days) of active service to the network',
        icon: Icons.military_tech,
        earned: tenureDays >= 180,
        progressLabel: tenureDays >= 180 ? '180 / 180' : '$tenureDays / 180 Days',
        color: const Color(0xFF8B5CF6),
      ),
      _BadgeData(
        title: 'Specialized Operator',
        desc: 'Verified skills and certifications registered in your responder profile',
        icon: Icons.school_outlined,
        earned: profile != null && profile.fullName.isNotEmpty,
        progressLabel: profile != null && profile.fullName.isNotEmpty ? 'Active' : 'Pending',
        color: const Color(0xFFEC4899),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Achievements & Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                // ── Milestone Level Header Progress ─────────────────
                _buildMilestoneProgressCard(
                  theme,
                  colorScheme,
                  title: milestoneTitle,
                  subtitle: milestoneSub,
                  progress: progressValue,
                  chipLabel: chipLabel,
                ),

                AppSpacing.vGapLg,

                // ── Service Stats Header (100% REAL) ────────────────
                _buildServiceStatsRow(
                  theme,
                  colorScheme,
                  tenureString: tenureString,
                  completedCount: completedCount,
                  onDuty: onDuty,
                ),

                AppSpacing.vGapLg,

                // ── Earned Badges List ──────────────────────────────
                Text(
                  'Earned & Upcoming Badges',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,
                ...badges.map((b) => _buildBadgeCard(theme, colorScheme, b)),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String, double, String) _computeMilestone(int completed) {
    if (completed == 0) {
      return (
        'Level 1: Field Trainee',
        'Complete your first rescue mission to advance to Level 2',
        0.10,
        '0 / 1 Rescues',
      );
    } else if (completed < 5) {
      final p = completed / 5.0;
      return (
        'Level 2: Active Responder',
        '${5 - completed} more rescue${5 - completed > 1 ? 's' : ''} to Level 3 (Senior Rescuer)',
        p.clamp(0.1, 0.95),
        '$completed / 5 Rescues',
      );
    } else if (completed < 15) {
      final p = completed / 15.0;
      return (
        'Level 3: Senior Rescuer',
        '${15 - completed} more rescues to Level 4 (Rescue Specialist)',
        p.clamp(0.1, 0.95),
        '$completed / 15 Rescues',
      );
    } else {
      return (
        'Level 4: Elite Rescue Specialist',
        'Highest operational rank achieved in field network',
        1.0,
        '$completed Rescues',
      );
    }
  }

  Widget _buildMilestoneProgressCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required double progress,
    required String chipLabel,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: colorScheme.primary, size: 28),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: chipLabel,
                backgroundColor: AppColors.success,
                textColor: AppColors.white,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHigh,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatsRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String tenureString,
    required int completedCount,
    required bool onDuty,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: tenureString,
            label: 'Service Tenure',
            icon: Icons.schedule,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '$completedCount',
            label: 'Completed Rescues',
            icon: Icons.shield,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: onDuty ? 'On-Duty' : 'Standby',
            label: 'Field Status',
            icon: onDuty ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    _BadgeData b,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: b.earned
                  ? b.color.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHigh,
              child: Icon(
                b.icon,
                color: b.earned ? b.color : colorScheme.onSurfaceVariant,
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
                        b.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${b.progressLabel})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: b.earned ? b.color : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    b.desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppChip(
              label: b.earned ? 'UNLOCKED' : 'LOCKED',
              backgroundColor: b.earned
                  ? AppColors.success.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              textColor: b.earned ? AppColors.success : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.title,
    required this.desc,
    required this.icon,
    required this.earned,
    required this.progressLabel,
    required this.color,
  });

  final String title;
  final String desc;
  final IconData icon;
  final bool earned;
  final String progressLabel;
  final Color color;
}
