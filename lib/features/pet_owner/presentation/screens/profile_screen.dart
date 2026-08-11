import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/layout/section_header.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';

/// The Pet Owner **Profile** screen (frozen "Community Profile", Light master).
///
/// The owner's own community profile: a glass header card (avatar, name, bio,
/// meta and an Edit action), a quick-stats pair, a "Recent Activity" post feed,
/// a "Top Badges" grid, "Joined Groups" and "Upcoming Events". All colors,
/// spacing, radii and type come from the theme / design tokens so one widget
/// tree serves both Light and Dark.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjI16jwSuB84Xzdt7-YtGGD8cXKVStGaG8oZWrTEE2O1-goYOuDRZcqSyPad1CPYiOtNpmKHsFuDGF1XWYq6EKqov84OOWCPHJxPpXKLuqTC6Q477BNMLO-6HiNHsNS4xCTdLYf92lsegzNK54T942Rm3uKfjS8--dRESAdQBH0TVmbgyvaZ_C4SsdIEjuXC5yT77JIkjPqIRey1hLpRcoeWF2RBXnU1DgCs_q6PoFUKKDG2FrJRTLfA';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: UserAvatar(imageUrl: _avatarUrl, size: 40),
      title: Text(
        'PetConnect AI',
        overflow: TextOverflow.ellipsis,
        style: text.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    return OwnerScaffold(
      currentTab: OwnerTab.profile,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          topPad + AppSpacing.md,
          AppSpacing.marginMobile,
          bottomPad,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeaderCard(avatarUrl: _avatarUrl),
                AppSpacing.vGapLg,
                const _QuickStats(),
                AppSpacing.vGapXl,
                SectionHeader(title: 'Recent Activity'),
                AppSpacing.vGapMd,
                const _ActivityPost(
                  title: 'Best hiking trails for senior dogs?',
                  group: 'Active Pets',
                  time: '2 hours ago',
                  body:
                      'Looking for some low-impact trails around the city that '
                      'are great for older dogs. My golden is 10 now and I want '
                      'to keep him moving without overdoing it. Any favorites?',
                  likes: 24,
                  comments: 8,
                ),
                AppSpacing.vGapMd,
                const _ActivityPost(
                  title: 'Graduation Day! 🎓',
                  group: 'Training Triumphs',
                  time: 'Yesterday',
                  body:
                      'So proud — we finally finished our advanced obedience '
                      'course. Positive reinforcement really does pay off.',
                  likes: 156,
                  comments: 32,
                  liked: true,
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjI16jwSuB84Xzdt7-YtGGD8cXKVStGaG8oZWrTEE2O1-goYOuDRZcqSyPad1CPYiOtNpmKHsFuDGF1XWYq6EKqov84OOWCPHJxPpXKLuqTC6Q477BNMLO-6HiNHsNS4xCTdLYf92lsegzNK54T942Rm3uKfjS8--dRESAdQBH0TVmbgyvaZ_C4SsdIEjuXC5yT77JIkjPqIRey1hLpRcoeWF2RBXnU1DgCs_q6PoFUKKDG2FrJRTLfA',
                ),
                AppSpacing.vGapXl,
                const _TopBadges(),
                AppSpacing.vGapXl,
                const _JoinedGroups(),
                AppSpacing.vGapXl,
                const _UpcomingEvents(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ── Header card ──────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brSection,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with surface ring + verified badge.
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 4),
                      ),
                      child: UserAvatar(imageUrl: avatarUrl, size: 88),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.verified,
                          size: AppIconSizes.xs,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.vGapSm,
                    Text(
                      'Alex Mercer',
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      'Golden Retriever Enthusiast & Local Guide',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,
          Text(
            'Passionate about dog training and exploring new trails. Always '
            'happy to share tips on positive reinforcement and finding the '
            'best pet-friendly cafes in town.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _MetaPill(icon: Icons.location_on, label: 'Seattle, WA'),
              _MetaPill(icon: Icons.calendar_month, label: 'Joined 2021'),
            ],
          ),
          AppSpacing.vGapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: AppIconSizes.sm),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xs, color: scheme.onSurfaceVariant),
          AppSpacing.hGapXs,
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stats ──────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            iconColor: scheme.primary,
            value: '4.2k',
            label: 'Helpful Votes',
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: _StatCard(
            icon: Icons.military_tech,
            iconColor: scheme.tertiary,
            value: '12',
            label: 'Badges Earned',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSizes.md, color: iconColor),
          AppSpacing.vGapMd,
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
// ── Activity post ──────────────────────────────────────────────────────────

class _ActivityPost extends StatelessWidget {
  const _ActivityPost({
    required this.title,
    required this.group,
    required this.time,
    required this.body,
    required this.likes,
    required this.comments,
    this.liked = false,
    this.imageUrl,
  });

  final String title;
  final String group;
  final String time;
  final String body;
  final int likes;
  final int comments;
  final bool liked;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text.rich(
                      TextSpan(
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Posted in '),
                          TextSpan(
                            text: group,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          TextSpan(text: ' • $time'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz,
                size: AppIconSizes.md,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Text(body, style: text.bodyMedium?.copyWith(color: scheme.onSurface)),
          if (imageUrl != null) ...[
            AppSpacing.vGapMd,
            ClipRRect(
              borderRadius: AppRadius.brMd,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_outlined,
                      color: scheme.onSurfaceVariant,
                      size: AppIconSizes.lg,
                    ),
                  ),
                ),
              ),
            ),
          ],
          AppSpacing.vGapMd,
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.10),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              _PostStat(
                icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: '$likes',
                color: liked ? scheme.primary : scheme.onSurfaceVariant,
              ),
              AppSpacing.hGapLg,
              _PostStat(
                icon: Icons.chat_bubble_outline,
                label: '$comments',
                color: scheme.onSurfaceVariant,
              ),
              const Spacer(),
              _PostStat(
                icon: Icons.share_outlined,
                label: 'Share',
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostStat extends StatelessWidget {
  const _PostStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSizes.sm, color: color),
        AppSpacing.hGapXs,
        Text(
          label,
          style: text.labelLarge?.copyWith(
            color: color,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}
// ── Top badges ─────────────────────────────────────────────────────────────

class _TopBadges extends StatelessWidget {
  const _TopBadges();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Top Badges',
          actionLabel: 'View All',
          onAction: () {},
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: _BadgeTile(
                icon: Icons.local_fire_department,
                color: scheme.tertiary,
                label: 'Hot Streak',
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _BadgeTile(
                icon: Icons.forum,
                color: scheme.secondary,
                label: 'Top Replier',
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _BadgeTile(
                icon: Icons.pets,
                color: scheme.primary,
                label: 'Pet Expert',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        children: [
          Icon(icon, size: AppIconSizes.lg, color: color),
          AppSpacing.vGapSm,
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Joined groups ────────────────────────────────────────────────────────

class _JoinedGroups extends StatelessWidget {
  const _JoinedGroups();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final rows = const [
      _GroupData(name: 'Positive Reinforcement Pros', members: '1.2k Members'),
      _GroupData(name: 'Seattle Dog Walkers', members: '850 Members'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Joined Groups'),
        AppSpacing.vGapMd,
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: AppRadius.brCard,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.10),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _GroupRow(data: rows[i]),
                if (i != rows.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.10),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupData {
  const _GroupData({required this.name, required this.members});
  final String name;
  final String members;
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.data});

  final _GroupData data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                Icons.groups,
                color: scheme.onSecondaryContainer,
                size: AppIconSizes.md,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: text.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    data.members,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant,
              size: AppIconSizes.md,
            ),
          ],
        ),
      ),
    );
  }
}
// ── Upcoming events ──────────────────────────────────────────────────────

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Upcoming Events'),
        AppSpacing.vGapMd,
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: AppRadius.brCard,
            border: Border(left: BorderSide(color: scheme.primary, width: 4)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Agility Course Basics',
                      style: text.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  _GoingPill(),
                ],
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: AppIconSizes.sm,
                    color: scheme.onSurfaceVariant,
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    'Oct 12 • 10:00 AM',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              Row(
                children: [
                  const _AttendeeStack(),
                  AppSpacing.hGapSm,
                  Text(
                    '+12 going',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoingPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        'GOING',
        style: text.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: AppTypography.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AttendeeStack extends StatelessWidget {
  const _AttendeeStack();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    Widget dot(IconData icon, Color bg, Color fg) => Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Icon(icon, size: AppIconSizes.xs - 4, color: fg),
    );

    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: [
          dot(
            Icons.person,
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
          ),
          Positioned(
            left: 20,
            child: dot(
              Icons.person,
              scheme.tertiaryContainer,
              scheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
