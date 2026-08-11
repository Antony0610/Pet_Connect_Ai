import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The Pet Owner **Pet Settings** screen.
///
/// A faithful Flutter rendering of the frozen Stitch "Pet Settings" (Light
/// master): a glass header carrying the pet avatar and an AI action, a
/// grouped settings list (rename, breed/type, privacy, notifications,
/// archive) and a destructive "Delete Pet Profile" danger zone. Every color,
/// spacing, radius and type comes from the theme / design tokens so one
/// widget tree serves both Light and Dark.
class PetSettingsScreen extends StatelessWidget {
  const PetSettingsScreen({super.key});

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjI16jwSuB84Xzdt7-YtGGD8cXKVStGaG8oZWrTEE2O1-goYOuDRZcqSyPad1CPYiOtNpmKHsFuDGF1XWYq6EKqov84OOWCPHJxPpXKLuqTC6Q477BNMLO-6HiNHsNS4xCTdLYf92lsegzNK54T942Rm3uKfjS8--dRESAdQBH0TVmbgyvaZ_C4SsdIEjuXC5yT77JIkjPqIRey1hLpRcoeWF2RBXnU1DgCs_q6PoFUKKDG2FrJRTLfA';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Row(
        children: [
          ClipOval(
            child: Image.network(
              _avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.pets,
                  size: AppIconSizes.sm,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          AppSpacing.hGapSm,
          Flexible(
            child: Text(
              'Pet Settings',
              overflow: TextOverflow.ellipsis,
              style: text.headlineSmall?.copyWith(
                color: scheme.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
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
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    final items = <_SettingRowData>[
      const _SettingRowData(
        icon: Icons.edit,
        title: 'Rename Pet',
        subtitle: 'Update Bella’s name',
      ),
      const _SettingRowData(
        icon: Icons.pets,
        title: 'Change Breed/Type',
        subtitle: 'Currently set to Golden Retriever',
      ),
      const _SettingRowData(
        icon: Icons.lock,
        title: 'Privacy Settings',
        subtitle: 'Manage who can see your pet',
      ),
      const _SettingRowData(
        icon: Icons.notifications_active,
        title: 'Notification Preferences',
        subtitle: 'Alerts for walks, meals, and vet',
      ),
      const _SettingRowData(
        icon: Icons.archive,
        title: 'Archive Pet',
        subtitle: 'Hide from main dashboard',
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
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
                // ── Settings list ──────────────────────────────────────
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
                      for (var i = 0; i < items.length; i++) ...[
                        _SettingRow(data: items[i], onTap: () {}),
                        if (i != items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.10,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Danger zone ────────────────────────────────────────
                _DeleteButton(
                  onTap: () => context.goNamed(RouteNames.ownerPetDelete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRowData {
  const _SettingRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.data, required this.onTap});

  final _SettingRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondaryContainer,
              ),
              child: Icon(
                data.icon,
                size: AppIconSizes.md,
                color: scheme.onSecondaryContainer,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: text.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    data.subtitle,
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

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.30),
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: scheme.error.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.error.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: AppIconSizes.md,
                  color: scheme.error,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Pet Profile',
                      style: text.titleMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      'Permanently remove this pet and data',
                      style: text.bodySmall?.copyWith(
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
    );
  }
}
