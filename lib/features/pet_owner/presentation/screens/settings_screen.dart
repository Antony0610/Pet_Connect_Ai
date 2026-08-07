import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../widgets/widgets.dart';

/// The Pet Owner **Settings** screen (frozen "Community Settings", Light
/// master).
///
/// A glass back-header ("Community Settings" + help), a settings menu, and the
/// Privacy / Interactions groups with toggles and navigable rows. All colors,
/// spacing, radii and type come from the theme / design tokens so one widget
/// tree serves both Light and Dark.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _publicProfile = true;
  bool _showLocation = false;

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
      title: Text(
        'Community Settings',
        overflow: TextOverflow.ellipsis,
        style: text.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.help_outline,
          tooltip: 'Help',
          onPressed: () {},
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

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
                // ── Settings menu ──────────────────────────────────────
                const _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.shield,
                      label: 'Privacy & Safety',
                      active: true,
                    ),
                    _MenuItem(
                      icon: Icons.notifications,
                      label: 'Notifications',
                    ),
                    _MenuItem(
                      icon: Icons.language,
                      label: 'Language & Region',
                    ),
                    _MenuItem(
                      icon: Icons.tune,
                      label: 'Content Preferences',
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Privacy ────────────────────────────────────────────
                _SettingsSection(
                  title: 'Privacy',
                  description:
                      'Manage who can see your profile and interact with you.',
                  children: [
                    _ToggleRow(
                      icon: Icons.public,
                      title: 'Public Profile',
                      subtitle:
                          "Allow anyone in the community to view your pet's "
                          'profile and recent activities.',
                      value: _publicProfile,
                      onChanged: (v) => setState(() => _publicProfile = v),
                    ),
                    _ToggleRow(
                      icon: Icons.location_on,
                      title: 'Show Location in Walks',
                      subtitle:
                          'Share your general neighborhood location when '
                          'posting walk summaries.',
                      value: _showLocation,
                      onChanged: (v) => setState(() => _showLocation = v),
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Interactions ───────────────────────────────────────
                _SettingsSection(
                  title: 'Interactions',
                  description: 'Control how others communicate with you.',
                  children: [
                    _NavRow(
                      icon: Icons.block,
                      title: 'Blocked Users',
                      subtitle: 'Manage the list of users you have blocked.',
                      onTap: () {},
                    ),
                    _NavRow(
                      icon: Icons.forum,
                      title: 'Message Requests',
                      subtitle: 'Choose who can send you direct messages.',
                      trailingValue: 'Friends Only',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ── Settings menu ────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              child: Material(
                color: item.active
                    ? scheme.primaryContainer
                    : Colors.transparent,
                borderRadius: AppRadius.brMd,
                child: InkWell(
                  onTap: () {},
                  borderRadius: AppRadius.brMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: AppIconSizes.md,
                          color: item.active
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        AppSpacing.hGapMd,
                        Text(
                          item.label,
                          style: text.titleSmall?.copyWith(
                            color: item.active
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                            fontWeight: item.active
                                ? AppTypography.semiBold
                                : AppTypography.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section container ────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
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
                Text(
                  description,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.10),
            ),
            children[i],
          ],
        ],
      ),
    );
  }
}
// ── Rows ─────────────────────────────────────────────────────────────────

class _RowScaffold extends StatelessWidget {
  const _RowScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppIconSizes.md, color: scheme.primary),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowScaffold(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingValue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingValue;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return _RowScaffold(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingValue != null) ...[
            Text(
              trailingValue!,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: AppTypography.medium,
              ),
            ),
            AppSpacing.hGapXs,
          ],
          Icon(
            Icons.chevron_right,
            size: AppIconSizes.md,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

