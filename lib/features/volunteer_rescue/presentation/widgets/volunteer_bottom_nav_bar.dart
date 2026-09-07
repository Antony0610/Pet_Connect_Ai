import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The five primary destinations of the Volunteer Rescue portal with Community Hub in the center.
enum VolunteerTab {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    routePath: RoutePaths.rescueHome,
  ),
  operations(
    label: 'Operations',
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    routePath: RoutePaths.rescueOperations,
  ),
  community(
    label: 'Community',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    routePath: RoutePaths.rescueCommunity,
  ),
  eoc(
    label: 'EOC / SOS',
    icon: Icons.emergency_outlined,
    activeIcon: Icons.emergency,
    routePath: RoutePaths.rescueEmergencyOps,
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    routePath: RoutePaths.rescueProfile,
  );

  const VolunteerTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.routePath,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String routePath;
}

/// The floating glassmorphic bottom navigation bar shared by Volunteer Rescue screens.
class VolunteerBottomNavBar extends StatelessWidget {
  const VolunteerBottomNavBar({
    required this.currentTab,
    super.key,
  });

  final VolunteerTab currentTab;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
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
                    .withValues(alpha: 0.85),
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final tab in VolunteerTab.values)
                    _VolunteerNavItem(
                      tab: tab,
                      isActive: tab == currentTab,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (tab == currentTab) return;
                        if (tab == VolunteerTab.dashboard) {
                          context.go(tab.routePath);
                        } else {
                          context.push(tab.routePath);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _VolunteerNavItem extends StatelessWidget {
  const _VolunteerNavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final VolunteerTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = PortalPalettes.of(AppPortal.volunteerRescue).accent;
    final color = isActive ? accent : scheme.onSurfaceVariant;

    final isCommunity = tab == VolunteerTab.community;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCommunity)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent.withValues(alpha: 0.20)
                        : accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    color: color,
                    size: AppIconSizes.md,
                  ),
                )
              else
                Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  color: color,
                  size: AppIconSizes.md,
                ),
              const SizedBox(height: AppSpacing.base),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10.5,
                    letterSpacing: -0.2,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
