import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The five primary destinations of the Pet Owner portal, in the frozen
/// bottom-navigation order.
enum OwnerTab {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    routeName: RouteNames.ownerHome,
  ),
  pets(
    label: 'My Pets',
    icon: Icons.pets_outlined,
    activeIcon: Icons.pets,
    routeName: RouteNames.ownerPets,
  ),
  community(
    label: 'Community',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    routeName: RouteNames.ownerCommunity,
  ),
  notifications(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    routeName: RouteNames.ownerNotifications,
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    routeName: RouteNames.ownerProfile,
  );

  const OwnerTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String routeName;
}

/// The floating glassmorphic bottom navigation bar shared by Pet Owner
/// screens.
///
/// Renders the frozen design's translucent, blurred pill fixed above the
/// bottom edge: the active tab is tinted with the Pet Owner emerald accent,
/// inactive tabs use `onSurfaceVariant`. All colors come from the theme /
/// portal palette so Light and Dark share one widget tree.
class OwnerBottomNavBar extends StatelessWidget {
  const OwnerBottomNavBar({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });

  final OwnerTab currentTab;
  final ValueChanged<OwnerTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.brPill,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.brPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: (isDark ? scheme.surfaceContainerLowest : scheme.surface)
                    .withValues(alpha: 0.80),
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final tab in OwnerTab.values)
                    _OwnerNavItem(
                      tab: tab,
                      isActive: tab == currentTab,
                      onTap: () => onTabSelected(tab),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerNavItem extends StatelessWidget {
  const _OwnerNavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final OwnerTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;
    final color = isActive ? accent : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? tab.activeIcon : tab.icon,
                color: color,
                size: AppIconSizes.md,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
