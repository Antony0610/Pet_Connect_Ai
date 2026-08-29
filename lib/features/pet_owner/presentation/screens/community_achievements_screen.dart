import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// Community Achievements & Gamification screen.
///
/// Driven dynamically by user activity: pets registered, community posts shared,
/// symptom triage scans conducted, and health milestones.
class CommunityAchievementsScreen extends ConsumerWidget {
  const CommunityAchievementsScreen({super.key});

  static const double _maxContentWidth = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;

    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final posts = ref.watch(communityPostsProvider(null)).valueOrNull ?? [];
    final scans = ref.watch(aiHealthScansProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProfileProvider).valueOrNull;

    // Filter user's own posts
    final myPosts = user != null
        ? posts.where((p) => p.userId == user.id).toList()
        : posts;

    // Dynamic XP calculation
    final petXp = pets.length * 300;
    final postXp = myPosts.length * 150;
    final scanXp = scans.length * 100;
    final totalXp = petXp + postXp + scanXp;

    final currentLevel = (totalXp / 500).floor() + 1;
    final nextLevelXp = currentLevel * 500;
    final currentLevelProgress = ((totalXp % 500) / 500).clamp(0.05, 1.0);

    String rankTitle = 'New Companion Parent';
    if (currentLevel >= 8) {
      rankTitle = 'Community Guide';
    } else if (currentLevel >= 5) {
      rankTitle = 'Devoted Caregiver';
    } else if (currentLevel >= 3) {
      rankTitle = 'Pet Enthusiast';
    } else if (currentLevel >= 2) {
      rankTitle = 'Active Member';
    }

    final totalLikes = myPosts.fold<int>(0, (sum, p) => sum + p.likesCount);

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
                  'Your Impact: Track your contributions and milestones across PetConnect AI.',
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
                            label: Text('Level $currentLevel'),
                            backgroundColor: scheme.primary,
                            labelStyle: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            rankTitle,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Keep caring for your companions, sharing community tips, and logging symptom triage to level up!',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP to Level ${currentLevel + 1}',
                            style: context.textTheme.labelMedium,
                          ),
                          Text(
                            '$totalXp / $nextLevelXp XP',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      LinearProgressIndicator(
                        value: currentLevelProgress,
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
                            value: '$totalLikes',
                            label: 'Helpful Votes',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.forum_outlined,
                            value: '${myPosts.length}',
                            label: 'Discussions',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.pets_outlined,
                            value: '${pets.length}',
                            label: 'Pets Tracked',
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.health_and_safety_outlined,
                            value: '${scans.length}',
                            label: 'Health Scans',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Earned Badges ──────────────────────────────────
                const SectionHeader(title: 'Milestone Badges'),
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
                      title: 'Companion Guardian',
                      description: pets.isNotEmpty ? 'Registered first companion' : 'Register 1 companion',
                      icon: Icons.pets,
                      isUnlocked: pets.isNotEmpty,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Health Sentinel',
                      description: scans.isNotEmpty ? 'Completed AI health scan' : 'Run an AI symptom scan',
                      icon: Icons.health_and_safety,
                      isUnlocked: scans.isNotEmpty,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Community Voice',
                      description: myPosts.isNotEmpty ? 'Published community post' : 'Share 1 post or question',
                      icon: Icons.forum_rounded,
                      isUnlocked: myPosts.isNotEmpty,
                    ),
                    _buildBadgeCard(
                      context,
                      title: 'Multi-Pet Champion',
                      description: pets.length >= 2 ? 'Managing 2+ companions' : 'Add 2 or more companions',
                      icon: Icons.groups,
                      isUnlocked: pets.length >= 2,
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Active Milestones Progress ──────────────────────
                const SectionHeader(title: 'Active Progress'),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Pet Care Foundation',
                  progressText: '${pets.length} / 2 Companions',
                  progressValue: (pets.length / 2).clamp(0.0, 1.0),
                  icon: Icons.pets,
                ),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Health Vigilance',
                  progressText: '${scans.length} / 3 AI Scans',
                  progressValue: (scans.length / 3).clamp(0.0, 1.0),
                  icon: Icons.psychology,
                ),
                AppSpacing.vGapSm,
                _buildMilestoneTile(
                  context,
                  title: 'Community Contributor',
                  progressText: '${myPosts.length} / 5 Posts',
                  progressValue: (myPosts.length / 5).clamp(0.0, 1.0),
                  icon: Icons.edit_note,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
