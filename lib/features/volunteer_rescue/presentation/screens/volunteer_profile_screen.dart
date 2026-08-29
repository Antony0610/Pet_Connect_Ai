import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Volunteer Profile Screen (Stitch ID: `0e2764c02d7e47a882bcff2157b0b1a9`).
class VolunteerProfileScreen extends ConsumerWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final missionsAsync = ref.watch(rescueMissionsProvider(null));
    final missions = missionsAsync.valueOrNull ?? [];
    final completedCount = missions.where((m) => m.status == 'completed' || m.status == 'resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.rescueHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.rescueSettings),
            tooltip: 'Volunteer Settings',
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
                // ── Profile Header Card ──────────────────────────────
                _buildProfileHeaderCard(context, theme, colorScheme, ref),

                AppSpacing.vGapLg,

                // ── Service Impact Metrics ───────────────────────────
                _buildMetricsGrid(theme, colorScheme, completedCount),

                AppSpacing.vGapLg,

                // ── Verification & Skill Badges ─────────────────────
                _buildSkillsSection(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Navigation Action List ──────────────────────────
                _buildNavigationList(context, theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final displayName = (userProfile != null && userProfile.fullName.isNotEmpty)
        ? userProfile.fullName
        : (userProfile != null && userProfile.email.isNotEmpty
            ? userProfile.email.split('@').first
            : 'Rescue Volunteer');
    final volId = userProfile != null && userProfile.id.length >= 6
        ? userProfile.id.substring(0, 6).toUpperCase()
        : 'VOL-01';

    final isOnDuty = ref.watch(volunteerDutyStatusProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 36, color: colorScheme.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 18, color: colorScheme.primary),
                  ],
                ),
                Text(
                  'ID: PC-$volId • Active Field Responder',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapXs,
                AppChip(
                  label: isOnDuty ? 'ON DUTY • ACTIVE DISPATCH' : 'STANDBY • OFF DUTY',
                  backgroundColor: isOnDuty ? AppColors.success : colorScheme.surfaceContainerHighest,
                  textColor: isOnDuty ? AppColors.white : colorScheme.onSurfaceVariant,
                ),
                AppSpacing.vGapSm,
                OutlinedButton.icon(
                  onPressed: () => _openEditVolunteerProfileDialog(context, ref, userProfile),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Responder Profile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditVolunteerProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile? currentProfile,
  ) async {
    final nameCtrl = TextEditingController(text: currentProfile?.fullName ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Responder Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volunteer Full Name',
                  hintText: 'e.g. Alex Morgan',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty && currentProfile != null) {
      final updated = currentProfile.copyWith(
        fullName: nameCtrl.text.trim(),
      );
      await ref.read(upsertUserProfileProvider)(updated);
      ref.invalidate(currentUserProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated for ${nameCtrl.text.trim()}!'),
          ),
        );
      }
    }
  }

  Widget _buildMetricsGrid(ThemeData theme, ColorScheme colorScheme, int completedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: completedCount > 0 ? '$completedCount' : '128',
            label: 'Rescues',
            icon: Icons.shield_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: '450h',
            label: 'Volunteered',
            icon: Icons.schedule_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: '12m',
            label: 'Avg Response',
            icon: Icons.timer_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
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

  Widget _buildSkillsSection(ThemeData theme, ColorScheme colorScheme) {
    final skills = [
      'First Aid Certified',
      'K9 Handler',
      'Water Rescue',
      'Disaster Relief',
      'Triage Lead',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Skills & Badges',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (s) => AppChip(
                  label: s,
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  textColor: colorScheme.primary,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Achievements & Milestones',
          subtitle: 'Track badging progress and service history',
          icon: Icons.emoji_events_outlined,
          onTap: () => context.push('/rescue/achievements'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Field Assistance & Support',
          subtitle: 'Emergency protocols and dispatch hotline',
          icon: Icons.help_outline,
          onTap: () => context.push('/rescue/assistance'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Pet Sharing & Foster Permissions',
          subtitle: 'Manage co-owner and temporary foster access',
          icon: Icons.share_outlined,
          onTap: () => context.push('/rescue/sharing'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Volunteer Preferences & Radius',
          subtitle: 'Configure availability days and alert radius',
          icon: Icons.tune_outlined,
          onTap: () => context.push('/rescue/settings'),
        ),
        AppSpacing.vGapLg,
        OutlinedButton.icon(
          icon: Icon(Icons.logout, color: colorScheme.error),
          label: Text('Sign Out of Rescue Portal', style: TextStyle(color: colorScheme.error)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Sign out of Volunteer & Rescue Portal?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              final container = ProviderScope.containerOf(context);
              await container.read(signOutProvider)(const NoParams());
              if (context.mounted) context.go(RoutePaths.login);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
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
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
