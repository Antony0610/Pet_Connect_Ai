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
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';

/// The Pet Owner **Notifications Center**.
///
/// A faithful Flutter rendering of the frozen Stitch "Notifications Center"
/// (Light master): the shared glass owner header, a "Mark all as read" action,
/// a horizontal row of category filter chips and a vertical feed of
/// notification cards (critical / AI / health / social) with unread markers.
/// All colors, spacing, radii and type come from the theme / design tokens so
/// one widget tree serves both Light and Dark.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// Notification visual/semantic kinds, each mapping to a theme token family.
enum _NotifKind { critical, ai, health, social }

/// Filterable categories shown as chips (in frozen order).
enum _NotifFilter {
  all('All'),
  health('Health'),
  ai('AI'),
  collar('Collar'),
  social('Social');

  const _NotifFilter(this.label);
  final String label;
}

class _NotifData {
  _NotifData({
    required this.kind,
    required this.filter,
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.body,
    this.unread = false,
    this.actionLabel,
    this.footerBadge,
  });

  final _NotifKind kind;
  final _NotifFilter filter;
  final IconData icon;
  final String title;
  final String timestamp;
  final String body;
  bool unread;
  final String? actionLabel;
  final String? footerBadge;
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _selected = _NotifFilter.all;

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjI16jwSuB84Xzdt7-YtGGD8cXKVStGaG8oZWrTEE2O1-goYOuDRZcqSyPad1CPYiOtNpmKHsFuDGF1XWYq6EKqov84OOWCPHJxPpXKLuqTC6Q477BNMLO-6HiNHsNS4xCTdLYf92lsegzNK54T942Rm3uKfjS8--dRESAdQBH0TVmbgyvaZ_C4SsdIEjuXC5yT77JIkjPqIRey1hLpRcoeWF2RBXnU1DgCs_q6PoFUKKDG2FrJRTLfA';

  late final List<_NotifData> _items = [
    _NotifData(
      kind: _NotifKind.critical,
      filter: _NotifFilter.collar,
      icon: Icons.battery_alert,
      title: 'Low Battery Warning',
      timestamp: '10m ago',
      body:
          "Bella's smart collar is at 5%. Please charge soon to maintain GPS "
          'tracking.',
      unread: true,
      footerBadge: 'High Priority',
    ),
    _NotifData(
      kind: _NotifKind.ai,
      filter: _NotifFilter.ai,
      icon: Icons.smart_toy,
      title: 'Activity Insight',
      timestamp: '1h ago',
      body:
          'AI Analysis: Charlie has been 20% less active today compared to his '
          'weekly average. Consider an extra evening walk.',
      unread: true,
    ),
    _NotifData(
      kind: _NotifKind.health,
      filter: _NotifFilter.health,
      icon: Icons.monitor_heart,
      title: 'Vaccination Reminder',
      timestamp: 'Yesterday',
      body: "Luna's annual checkup and rabies vaccination are due next week.",
      unread: true,
      actionLabel: 'Schedule Appointment',
    ),
    _NotifData(
      kind: _NotifKind.social,
      filter: _NotifFilter.social,
      icon: Icons.favorite,
      title: 'New Follower',
      timestamp: '2d ago',
      body: 'Max the Beagle started following your pack!',
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.unread = false;
      }
    });
  }

  List<_NotifData> get _visible => _selected == _NotifFilter.all
      ? _items
      : _items.where((i) => i.filter == _selected).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: _AvatarButton(
        imageUrl: _avatarUrl,
        onTap: () => context.goNamed(RouteNames.ownerProfile),
      ),
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
    final visible = _visible;

    return OwnerScaffold(
      currentTab: OwnerTab.notifications,
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
                // ── Header row ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: text.headlineMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        'Mark all as read',
                        style: text.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,

                // ── Category filter chips ──────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _NotifFilter.values.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (context, i) {
                      final filter = _NotifFilter.values[i];
                      return _FilterChip(
                        label: filter.label,
                        selected: filter == _selected,
                        onTap: () => setState(() => _selected = filter),
                      );
                    },
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Feed ───────────────────────────────────────────────
                if (visible.isEmpty)
                  _EmptyState()
                else
                  for (var i = 0; i < visible.length; i++) ...[
                    _NotificationCard(data: visible[i]),
                    if (i != visible.length - 1) AppSpacing.vGapMd,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: UserAvatar(imageUrl: imageUrl, size: 40),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainer,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: selected
                ? null
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.40),
                  ),
          ),
          child: Text(
            label,
            style: text.labelLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: AppIconSizes.xl,
            color: scheme.onSurfaceVariant,
          ),
          AppSpacing.vGapMd,
          Text(
            'No notifications here',
            style: text.titleMedium?.copyWith(color: scheme.onSurface),
          ),
          AppSpacing.vGapXs,
          Text(
            "You're all caught up.",
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Resolved token bundle for a notification [_NotifKind].
class _KindStyle {
  const _KindStyle({
    required this.badgeBg,
    required this.badgeFg,
    required this.titleColor,
  });

  final Color badgeBg;
  final Color badgeFg;
  final Color titleColor;

  factory _KindStyle.of(_NotifKind kind, ColorScheme scheme) {
    switch (kind) {
      case _NotifKind.critical:
        return _KindStyle(
          badgeBg: scheme.error,
          badgeFg: scheme.onError,
          titleColor: scheme.error,
        );
      case _NotifKind.ai:
        return _KindStyle(
          badgeBg: scheme.primaryContainer,
          badgeFg: scheme.onPrimaryContainer,
          titleColor: scheme.onSurface,
        );
      case _NotifKind.health:
        return _KindStyle(
          badgeBg: scheme.secondaryContainer,
          badgeFg: scheme.onSecondaryContainer,
          titleColor: scheme.onSurface,
        );
      case _NotifKind.social:
        return _KindStyle(
          badgeBg: scheme.tertiaryContainer,
          badgeFg: scheme.onTertiaryContainer,
          titleColor: scheme.onSurface,
        );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.data});

  final _NotifData data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final style = _KindStyle.of(data.kind, scheme);
    final isCritical = data.kind == _NotifKind.critical;
    final isAi = data.kind == _NotifKind.ai;

    // Card surface: critical uses a tinted error wash; read items dim to 70%.
    final surface = isCritical
        ? scheme.errorContainer.withValues(alpha: 0.10)
        : scheme.surfaceContainerLowest;
    final borderColor = isCritical
        ? scheme.error.withValues(alpha: 0.20)
        : scheme.outlineVariant.withValues(alpha: 0.10);

    Widget card = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: borderColor),
        // AI insight carries a subtle primary→secondary gradient edge.
        gradient: isAi
            ? LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.06),
                  scheme.secondary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.badgeBg,
            ),
            child: Icon(data.icon, size: AppIconSizes.sm, color: style.badgeFg),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: text.titleMedium?.copyWith(
                          color: style.titleColor,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      data.timestamp,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (data.unread) ...[
                      AppSpacing.hGapSm,
                      Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  data.body,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (data.footerBadge != null) ...[
                  AppSpacing.vGapMd,
                  _PriorityBadge(label: data.footerBadge!),
                ],
                if (data.actionLabel != null) ...[
                  AppSpacing.vGapXs,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          context.goNamed(RouteNames.ownerHealthVaccinations),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        data.actionLabel!,
                        style: text.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!data.unread) {
      card = Opacity(opacity: 0.70, child: card);
    }
    return card;
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label});

  final String label;

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
        color: scheme.error,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: scheme.onError,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
