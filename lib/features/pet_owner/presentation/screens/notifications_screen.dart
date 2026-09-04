import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/volunteer_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';

/// The role-aware **Notifications Center** supporting Pet Owner, Vet, and Volunteer portals.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    this.portalRole = AppPortal.petOwner,
    super.key,
  });

  final AppPortal portalRole;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
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
    required this.id,
    required this.kind,
    required this.filter,
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.body,
    this.unread = false,
    this.footerBadge,
    this.payload = const {},
  });

  final String id;
  final _NotifKind kind;
  final _NotifFilter filter;
  final IconData icon;
  final String title;
  final String timestamp;
  final String body;
  bool unread;
  final String? footerBadge;
  final Map<String, dynamic> payload;

  factory _NotifData.fromEntity(UserNotification entity) {
    final typeUpper = entity.notificationType.toUpperCase();
    _NotifKind kind;
    _NotifFilter filter;
    IconData icon;
    String? footerBadge;

    if (typeUpper.contains('CRITICAL') ||
        typeUpper.contains('BATTERY') ||
        typeUpper.contains('GEOFENCE')) {
      kind = _NotifKind.critical;
      filter = _NotifFilter.collar;
      icon =
          typeUpper.contains('BATTERY') ? Icons.battery_alert : Icons.warning;
      footerBadge = 'High Priority';
    } else if (typeUpper.contains('COLLAR')) {
      kind = _NotifKind.critical;
      filter = _NotifFilter.collar;
      icon = Icons.pets;
    } else if (typeUpper.contains('AI')) {
      kind = _NotifKind.ai;
      filter = _NotifFilter.ai;
      icon = Icons.smart_toy;
    } else if (typeUpper.contains('HEALTH') ||
        typeUpper.contains('APPOINTMENT') ||
        typeUpper.contains('VACCINE')) {
      kind = _NotifKind.health;
      filter = _NotifFilter.health;
      icon = Icons.monitor_heart;
    } else {
      kind = _NotifKind.social;
      filter = _NotifFilter.social;
      icon = (typeUpper.contains('COMMENT') || entity.title.toLowerCase().contains('comment') || entity.body.toLowerCase().contains('comment'))
          ? Icons.chat_bubble_rounded
          : Icons.favorite_rounded;
    }

    final now = DateTime.now();
    final diff = now.difference(entity.createdAt);
    String timestamp;
    if (diff.inMinutes < 1) {
      timestamp = 'Just now';
    } else if (diff.inMinutes < 60) {
      timestamp = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timestamp = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      timestamp = '${diff.inDays}d ago';
    } else {
      timestamp =
          '${entity.createdAt.month}/${entity.createdAt.day}/${entity.createdAt.year}';
    }

    return _NotifData(
      id: entity.id,
      kind: kind,
      filter: filter,
      icon: icon,
      title: entity.title,
      timestamp: timestamp,
      body: entity.body,
      unread: !entity.isRead,
      footerBadge: footerBadge,
      payload: entity.payload,
    );
  }
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotifFilter _selected = _NotifFilter.all;

  Future<void> _markAllRead() async {
    try {
      await ref.read(userNotificationsProvider.notifier).markAllRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will delete all notifications from your account. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(userNotificationsProvider.notifier).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    // Listen to live realtime notifications
    ref.listen<AsyncValue<UserNotification>>(
      liveUserNotificationsStreamProvider,
      (previous, next) {
        next.whenData((notif) {
          ref.read(userNotificationsProvider.notifier).addLiveNotification(notif);
        });
      },
    );

    final notificationsAsync = ref.watch(userNotificationsProvider);
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;

    final appBar = OwnerGlassAppBar(
      leading: _AvatarButton(
        imageUrl: userProfile?.avatarUrl ?? '',
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

    if (widget.portalRole == AppPortal.veterinarian) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Veterinary Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(RoutePaths.vetHome);
              }
            },
          ),
        ),
        bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.dashboard),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: _buildNotificationsBody(context, scheme, text, notificationsAsync),
            ),
          ),
        ),
      );
    }

    if (widget.portalRole == AppPortal.volunteerRescue) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rescue Incident Alerts'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(RoutePaths.rescueHome);
              }
            },
          ),
        ),
        bottomNavigationBar: const VolunteerBottomNavBar(currentTab: VolunteerTab.dashboard),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: _buildNotificationsBody(context, scheme, text, notificationsAsync),
            ),
          ),
        ),
      );
    }

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    return OwnerScaffold(
      currentTab: OwnerTab.home,
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
            child: _buildNotificationsBody(context, scheme, text, notificationsAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsBody(
    BuildContext context,
    ColorScheme scheme,
    TextTheme text,
    AsyncValue<List<UserNotification>> notificationsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header row ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                widget.portalRole == AppPortal.veterinarian
                    ? 'Clinical Alerts'
                    : widget.portalRole == AppPortal.volunteerRescue
                        ? 'Emergency Alerts'
                        : 'Notifications',
                style: text.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: text.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear all',
                style: text.labelMedium?.copyWith(
                  color: scheme.error,
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
                notificationsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        'Error loading notifications: $err',
                        style: text.bodyMedium?.copyWith(color: scheme.error),
                      ),
                    ),
                  ),
                  data: (entities) {
                    final filteredEntities = entities.where((e) {
                      if (widget.portalRole == AppPortal.petOwner) {
                        final type = e.notificationType.toLowerCase();
                        final title = e.title.toLowerCase();
                        // Filter out clinical veterinarian consultation alerts from the Pet Owner portal
                        if (type == 'vet_consultation' ||
                            type == 'clinical_alert' ||
                            (type == 'consultation' && title.contains('new consultation:'))) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    final allItems =
                        filteredEntities.map(_NotifData.fromEntity).toList();
                    final visible =
                        _selected == _NotifFilter.all
                            ? allItems
                            : allItems
                                .where((i) => i.filter == _selected)
                                .toList();

                    if (visible.isEmpty) {
                      return _EmptyState();
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          Dismissible(
                            key: ValueKey('notif-${visible[i].id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppSpacing.lg),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: AppRadius.brCard,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Clear',
                                    style: text.labelMedium?.copyWith(
                                      color: scheme.onErrorContainer,
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                  AppSpacing.hGapSm,
                                  Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              final id = visible[i].id;
                              ref.read(userNotificationsProvider.notifier).deleteNotification(id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: _NotificationCard(
                              data: visible[i],
                              onTap: () async {
                                if (visible[i].unread) {
                                  await ref
                                      .read(userNotificationsProvider.notifier)
                                      .markRead(visible[i].id);
                                }
                                if (!context.mounted) return;
                                final item = visible[i];
                                final t = item.title.toLowerCase();
                                final b = item.body.toLowerCase();
                                final postId = item.payload['post_id'] as String?;
                                final commentId = item.payload['comment_id'] as String?;

                                if (widget.portalRole == AppPortal.veterinarian) {
                                  if (item.filter == _NotifFilter.health || t.contains('appointment') || t.contains('schedule')) {
                                    await context.push(RoutePaths.vetAppointments);
                                  } else {
                                    await context.push(RoutePaths.vetQueue);
                                  }
                                  return;
                                }

                                if (widget.portalRole == AppPortal.volunteerRescue) {
                                  if (t.contains('emergency') || t.contains('sos') || t.contains('p1')) {
                                    await context.push(RoutePaths.rescueEmergencyOps);
                                  } else {
                                    await context.push(RoutePaths.rescueOperations);
                                  }
                                  return;
                                }

                                if (item.filter == _NotifFilter.social ||
                                    t.contains('comment') ||
                                    t.contains('like') ||
                                    b.contains('comment') ||
                                    b.contains('liked') ||
                                    b.contains('loved') ||
                                    postId != null) {
                                  if (postId != null && postId.isNotEmpty) {
                                    final queryParams = <String, String>{'postId': postId};
                                    if (commentId != null && commentId.isNotEmpty) {
                                      queryParams['commentId'] = commentId;
                                    }
                                    final uri = Uri(path: RoutePaths.ownerCommunity, queryParameters: queryParams);
                                    await context.push(uri.toString());
                                  } else {
                                    await context.push(RoutePaths.ownerCommunity);
                                  }
                                } else if (item.filter == _NotifFilter.collar ||
                                    t.contains('collar') ||
                                    t.contains('battery') ||
                                    t.contains('geofence')) {
                                  await context.push(RoutePaths.ownerCollarTracking);
                                } else if (item.filter == _NotifFilter.health ||
                                    t.contains('health') ||
                                    t.contains('vaccine') ||
                                    t.contains('prescription')) {
                                  await context.push(RoutePaths.ownerHealthMedical);
                                } else if (item.filter == _NotifFilter.ai) {
                                  await context.push(RoutePaths.ownerAiChat);
                                }
                              },
                            ),
                          ),
                          if (i != visible.length - 1) AppSpacing.vGapMd,
                        ],
                      ],
                    );
                  },
                ),
              ],
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
            border:
                selected
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
  const _NotificationCard({required this.data, this.onTap});

  final _NotifData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final style = _KindStyle.of(data.kind, scheme);
    final isCritical = data.kind == _NotifKind.critical;
    final isAi = data.kind == _NotifKind.ai;

    final surface =
        isCritical
            ? scheme.errorContainer.withValues(alpha: 0.10)
            : scheme.surfaceContainerLowest;
    final borderColor =
        isCritical
            ? scheme.error.withValues(alpha: 0.20)
            : scheme.outlineVariant.withValues(alpha: 0.10);

    Widget card = InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brCard,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: borderColor),
          gradient:
              isAi
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.badgeBg,
              ),
              child: Icon(
                data.icon,
                size: AppIconSizes.sm,
                color: style.badgeFg,
              ),
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
                ],
              ),
            ),
          ],
        ),
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
