import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The five primary destinations of the Administrator Command portal.
enum AdminTab {
  directory(
    label: 'Directory',
    icon: Icons.manage_accounts_outlined,
    activeIcon: Icons.manage_accounts,
    routePath: RoutePaths.adminUsers,
  ),
  staff(
    label: 'Staff',
    icon: Icons.badge_outlined,
    activeIcon: Icons.badge,
    routePath: RoutePaths.adminStaff,
  ),
  content(
    label: 'Content',
    icon: Icons.article_outlined,
    activeIcon: Icons.article,
    routePath: RoutePaths.adminContent,
  ),
  health(
    label: 'Health',
    icon: Icons.dns_outlined,
    activeIcon: Icons.dns,
    routePath: RoutePaths.adminHealth,
  ),
  settings(
    label: 'Settings',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune,
    routePath: RoutePaths.adminSettings,
  );

  const AdminTab({
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

/// Floating glassmorphic bottom navigation bar for Administrator portal.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    required this.currentTab,
    super.key,
  });

  final AdminTab currentTab;

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
                    .withValues(alpha: 0.85),
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: AdminTab.values.map((tab) {
                  final isSelected = tab == currentTab;
                  return Expanded(
                    child: _AdminNavItem(
                      tab: tab,
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) return;
                        HapticFeedback.lightImpact();
                        context.go(tab.routePath);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final AdminTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    final selectedBg = scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12);
    final selectedIconColor = scheme.primary;
    final unselectedIconColor = scheme.onSurfaceVariant.withValues(alpha: 0.65);

    return Semantics(
      label: tab.label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        splashColor: scheme.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: AppRadius.brPill,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  key: ValueKey('${tab.name}_$isSelected'),
                  size: AppIconSizes.md,
                  color: isSelected ? selectedIconColor : unselectedIconColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedIconColor : unselectedIconColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
