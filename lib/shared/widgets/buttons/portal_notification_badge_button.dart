import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';

/// An AppBar notification bell button featuring a live, reactive unread counter badge.
class PortalNotificationBadgeButton extends ConsumerWidget {
  const PortalNotificationBadgeButton({
    required this.onPressed,
    this.tooltip = 'Notifications & Alerts',
    super.key,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final theme = Theme.of(context);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: theme.colorScheme.error,
        textColor: theme.colorScheme.onError,
        label: Text(
          unreadCount > 99 ? '99+' : '$unreadCount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
