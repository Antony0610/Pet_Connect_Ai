import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import 'owner_app_bar.dart';

/// Shared building blocks for the Pet Owner **Health Passport** module.
///
/// These render the recurring pieces of the frozen Stitch health screens —
/// the glass top bar, the "Buddy" pet avatar, colored record rows, category
/// chips, card headers and empty-state boxes — so the five health screens
/// compose them instead of duplicating layout. Every color, radius, spacing
/// and type value comes from the design tokens / theme, so one widget tree
/// serves both Light and Dark.
library;

/// The featured pet across the frozen health comps ("Buddy").
const String kHealthPetPhotoUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDAxfTvenWKVtwB-grFwZuhHc5SFWE9GAkouJdryUqMJkXF7oUoBAgsf1G71O2gXLSpxiw6zhsGL3T-9qrsYhL-YdgFRxGcpjlTLAtWVtOqiQgpuXuVnReIx19qI7KLm1A6mY3EQOcTMcbIP4PsK2IxuiWGKotKvo7u3mvmWvFmlpfuxdsS_t08QRYzs_v_dTj61EhFGfM60uIgcSTis_8njKUj_M0YI7bjqqfCDJ6xBKqDwQnlCo62pw';

/// Builds the frozen health glass app bar: a back button, a `primary` bold
/// title and a trailing bordered pet avatar that taps through to Profile.
OwnerGlassAppBar healthAppBar(BuildContext context, {required String title}) {
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
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: HealthPetAvatar(
          size: 40,
          onTap: () => context.goNamed(RouteNames.ownerProfile),
        ),
      ),
    ],
  );
}

/// A circular pet avatar with a soft `primary` rim, used in the health app bar.
class HealthPetAvatar extends StatelessWidget {
  const HealthPetAvatar({required this.size, this.onTap, super.key});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.20),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          kHealthPetPhotoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: scheme.secondaryContainer,
            child: Icon(
              Icons.pets_rounded,
              size: size * 0.5,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}

/// The frozen emerald call-to-action button used across the health screens
/// (Share Milestone, Schedule Appointment, Log Assessment…).
///
/// [AppButton] paints with the theme's `primary`; the health comps want the
/// Pet Owner **accent** (emerald), so this wraps a [FilledButton] whose colors
/// come from the passed [accent] token — never a literal.
class HealthAccentButton extends StatelessWidget {
  const HealthAccentButton({
    required this.label,
    required this.accent,
    required this.onAccent,
    this.icon,
    this.onPressed,
    this.isFullWidth = true,
    super.key,
  });

  final String label;
  final Color accent;
  final Color onAccent;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: onAccent,
      minimumSize: Size(isFullWidth ? double.infinity : 0, 48),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
      textStyle: context.textTheme.titleSmall?.copyWith(
        fontWeight: AppTypography.bold,
      ),
    );

    if (icon == null) {
      return FilledButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: AppIconSizes.sm),
      label: Text(label),
    );
  }
}

/// A filled circular icon badge (leading element for record rows / headers).
class HealthCircleIcon extends StatelessWidget {
  const HealthCircleIcon({
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

/// A compact category / status pill: container-tinted background with an
/// optional leading icon. Matches the frozen "Surgery / Visit / Medical" chips.
class HealthCategoryChip extends StatelessWidget {
  const HealthCategoryChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.border,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? border;

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
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.xs, color: foreground),
            AppSpacing.hGapXs,
          ],
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

/// A single meta line under a record title (e.g. a date or clinic), with an
/// optional small leading icon in `onSurfaceVariant`.
class HealthMetaLine {
  const HealthMetaLine(this.text, {this.icon});

  final String text;
  final IconData? icon;
}

/// A record / list row: leading badge, a title, zero or more meta lines and a
/// trailing element (chevron or action). Used by every health list.
class HealthRecordRow extends StatelessWidget {
  const HealthRecordRow({
    required this.leading,
    required this.title,
    this.meta = const [],
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final String title;
  final List<HealthMetaLine> meta;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              for (final line in meta) ...[
                AppSpacing.vGapXs,
                Row(
                  children: [
                    if (line.icon != null) ...[
                      Icon(
                        line.icon,
                        size: AppIconSizes.xs,
                        color: scheme.onSurfaceVariant,
                      ),
                      AppSpacing.hGapXs,
                    ],
                    Expanded(
                      child: Text(
                        line.text,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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

/// A card header: a colored circular icon and a title, with an optional
/// trailing widget. Matches "Known Allergies", "Upcoming Next" etc.
class HealthCardHeader extends StatelessWidget {
  const HealthCardHeader({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HealthCircleIcon(
          icon: icon,
          background: iconBackground,
          foreground: iconColor,
          size: 40,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A dashed-border empty state ("None reported") used by the medical cards.
class HealthEmptyBox extends StatelessWidget {
  const HealthEmptyBox({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: scheme.outlineVariant,
        radius: AppRadius.md,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant, size: AppIconSizes.lg),
            AppSpacing.vGapXs,
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a rounded dashed rectangle border (Flutter has no built-in dash).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
