import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Achievements**
/// (Light Theme design authority, ID `733b0984`).
///
/// Displays community gamification metrics, user impact levels, earned badges,
/// helpful votes, and active milestone progress.
class CommunityAchievementsScreen extends StatelessWidget {
  const CommunityAchievementsScreen({super.key});

  static const double _maxContentWidth = 1000;

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
          'Community Achievements',
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
                // ── Subtitle Banner ────────────────────────────────
                Text(
                  "Your Impact: You're making waves in the PetConnect community.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── User Impact Level Hero Card ────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              Icons.star,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                            label: const Text('Level 14'),
                            backgroundColor: scheme.primary,
                            labelStyle: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'Community Guide',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'You are in the top 5% of active contributors this month. Your shared experiences are helping hundreds of pet parents.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP to Level 15',
                            style: context.textTheme.labelMedium,
                          ),
                          Text(
                            '8,450 / 10,000 XP',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      LinearProgressIndicator(
                        value: 0.845,
                        backgroundColor: scheme.surfaceContainerHigh,
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      AppSpacing.vGapLg,

                      // ── Impact Stats Grid ────────────────────────
                      Row(
                        children: [
                          _buildStatItem(
                            context,
                            icon: Icons.thumb_up_alt_outlined,
                            value: '342',
                            label: 'Helpful Votes',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.share_outlined,
                            value: '89',
                            label: 'Shares',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.forum_outlined,
                            value: '156',
                            label: 'Discussions',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.local_fire_department_outlined,
                            value: '12',
                            label: 'Day Streak',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Earned Badges ──────────────────────────────────
                const SectionHeader(title: 'Earned Badges'),
                AppSpacing.vGapSm,
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 2.2,
                  children: [
                    _buildBadgeCard(
                      context,
                      title: 'Helpful Contributor',
                      description: 'Received 100+ upvotes',
                      icon: Icons.workspace_premium,
                      isUnlocked: true,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Knowledge Sharer',
                      description: 'Posted 50 detailed guides',
                      icon: Icons.menu_book,
                      isUnlocked: true,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Volunteer Supporter',
                      description: 'Helped 20 rescued pets',
                      icon: Icons.volunteer_activism,
                      isUnlocked: true,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Local Legend',
                      description: 'Host a community walk',
                      icon: Icons.lock,
                      isUnlocked: false,
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Active Milestones Progress ──────────────────────
                const SectionHeader(title: 'Active Milestones'),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Pack Leader',
                  progressText: '45 / 50 Friends',
                  progressValue: 0.9,
                  icon: Icons.groups,
                ),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Shutterbug',
                  progressText: '12 / 20 Photos Shared',
                  progressValue: 0.6,
                  icon: Icons.photo_camera,
                ),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Trusted Reviewer',
                  progressText: '2 / 10 Park Reviews',
                  progressValue: 0.2,
                  icon: Icons.verified,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final scheme = context.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: AppIconSizes.md),
          AppSpacing.vGapXs,
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      backgroundColor: isUnlocked
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUnlocked
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            child: Icon(
              icon,
              color: isUnlocked ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: isUnlocked
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile(
    BuildContext context, {
    required String title,
    required String progressText,
    required double progressValue,
    required IconData icon,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              AppSpacing.hGapSm,
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              const Spacer(),
              Text(
                progressText,
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: scheme.surfaceContainerHigh,
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ],
      ),
    );
  }
}
