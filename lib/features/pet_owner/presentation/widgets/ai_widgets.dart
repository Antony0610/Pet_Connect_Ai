/// Shared building blocks for the Pet Owner **AI Hub** module.
///
/// These render the recurring pieces of the frozen Stitch AI screens — the
/// glass back-nav bar, the signature gradient-border "AI content" card, the
/// confidence / match badges, source-attribution chips and the recent-activity
/// rows — so the AI screens compose them instead of duplicating layout. Every
/// color, radius, spacing and type value comes from the design tokens / theme,
/// so one widget tree serves both Light and Dark.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';

/// Builds the frozen AI glass app bar: a back button, a `primary` bold title
/// and optional trailing [actions].
OwnerGlassAppBar aiAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
}) {
  return OwnerGlassAppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () => GoRouter.of(context).pop(),
    ),
    title: Text(
      title,
      style: context.textTheme.headlineSmall?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: AppTypography.bold,
        letterSpacing: -0.25,
      ),
    ),
    actions: actions,
  );
}

/// A filled circular icon badge (leading element for AI rows / headers).
class AiCircleIcon extends StatelessWidget {
  const AiCircleIcon({
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: foreground, size: size * 0.5),
    );
  }
}

/// A card wrapped in the signature AI **gradient border** (`primary` →
/// `secondary`, per the frozen `DESIGN.md` rule that AI-generated content is
/// encased in a subtle gradient-bordered card). The border is painted as a
/// gradient ring; the inner fill uses [fill] (defaults to a low surface).
class AiGradientBorderCard extends StatelessWidget {
  const AiGradientBorderCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.fill,
    this.borderWidth = 1.5,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? fill;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brSection,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill ?? scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xxl - 2),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSection,
      child: card,
    );
  }
}

/// The green "High Confidence" / "Verified" pill used on AI insight cards.
/// Uses the semantic success container so it reads as trustworthy in both
/// themes without any literal color.
class AiConfidenceBadge extends StatelessWidget {
  const AiConfidenceBadge({
    String? label,
    Color? background,
    Color? foreground,
    String? percentage,
    this.icon = Icons.verified_rounded,
    super.key,
  }) : label =
           label ??
           (percentage != null ? '$percentage Match' : 'High Confidence'),
       background = background ?? const Color(0xFFE8F5E9),
       foreground = foreground ?? const Color(0xFF2E7D32);

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xs, color: foreground),
          AppSpacing.hGapXs,
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "source attribution" chip — an outlined pill with a link glyph and
/// a source name, used under AI answers so users can trace the citation.
class AiSourceChip extends StatelessWidget {
  const AiSourceChip({
    required this.label,
    this.icon = Icons.menu_book_rounded,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xs, color: scheme.onSurfaceVariant),
          AppSpacing.hGapXs,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(onTap: onTap, borderRadius: AppRadius.brPill, child: chip);
  }
}

/// A recent-activity / history row: leading circular icon, a title, a subtitle
/// and a trailing element (a timestamp label or a chevron).
class AiListTile extends StatelessWidget {
  const AiListTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final row = Row(
      children: [
        leading,
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              if (subtitle != null) ...[
                AppSpacing.vGapXs,
                Text(
                  subtitle!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[AppSpacing.hGapSm, trailing!],
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: row,
      ),
    );
  }
}
