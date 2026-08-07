import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// The glassmorphic top app bar shared across Pet Owner screens.
///
/// Renders the frozen design's fixed header: a translucent surface with a
/// `backdrop-filter: blur(20px)` and a soft bottom hairline, so page content
/// scrolls and blurs beneath it. Pair with `Scaffold(extendBodyBehindAppBar:
/// true)`.
///
/// [leading], [title] and [actions] are laid out in a single row; colors come
/// from the active [ColorScheme] so Light and Dark share one widget tree.
class OwnerGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OwnerGlassAppBar({
    this.leading,
    this.title,
    this.actions = const <Widget>[],
    this.toolbarHeight = 64,
    super.key,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final topInset = context.viewPadding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: toolbarHeight + topInset,
          padding: EdgeInsets.only(
            top: topInset,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
          ),
          decoration: BoxDecoration(
            color: (isDark ? scheme.surface : scheme.surface).withValues(
              alpha: 0.60,
            ),
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.20),
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                AppSpacing.hGapSm,
              ],
              if (title != null) Expanded(child: title!),
              if (title == null) const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// The emerald "pets" brand mark + screen title used on the Home header.
class OwnerAppBarBrand extends StatelessWidget {
  const OwnerAppBarBrand({required this.title, required this.accent, super.key});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.base + 2),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: const Icon(
            Icons.pets,
            color: Colors.white,
            size: AppIconSizes.sm,
          ),
        ),
        AppSpacing.hGapSm,
        Text(
          title,
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A circular, borderless icon action for the glass app bar. Shows an optional
/// notification [badge] dot in the accent/error color.
class OwnerAppBarAction extends StatelessWidget {
  const OwnerAppBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.showBadge = false,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool showBadge;

  /// Icon tint; defaults to [ColorScheme.onSurfaceVariant] when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: color ?? scheme.onSurfaceVariant,
      iconSize: AppIconSizes.md,
    );

    if (!showBadge) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
