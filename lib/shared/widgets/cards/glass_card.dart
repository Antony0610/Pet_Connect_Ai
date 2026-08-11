import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/tokens/app_elevation.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';

/// A glassmorphic ("Premium Expressive") surface container.
///
/// Renders the frozen design's `.glass-card`: a translucent surface with a
/// `backdrop-filter: blur(20px)`, a hairline light border and the soft
/// ambient [AppElevation.shadowSoft] shadow. In the frozen Light spec this is
/// `background: rgba(255,255,255,0.7)` with a `rgba(255,255,255,0.3)` border;
/// the Dark derivation swaps only theme-dependent values — a translucent dark
/// tonal surface with a low-opacity light hairline — so a single widget tree
/// serves both themes.
///
/// All colors derive from the active [ColorScheme]/[Brightness]; nothing is
/// hard-coded. Consume this instead of re-implementing blur surfaces.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.brSection,
    this.onTap,
    this.blurSigma = 20,
    this.clipContent = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  /// Gaussian blur sigma behind the surface — the design uses `blur(20px)`.
  final double blurSigma;

  /// Whether the surface clips its child to [borderRadius]. Disable when the
  /// child intentionally overflows (e.g. a floating badge).
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Translucent surface: 70% in Light (per spec), a slightly more opaque
    // tonal surface in Dark so content stays legible over dark backgrounds.
    final surface = isDark
        ? colorScheme.surfaceContainer.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerLowest.withValues(alpha: 0.70);

    // Hairline "frosted" edge — a light border in Light, a faint light border
    // in Dark to catch the glass highlight.
    final borderColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.10)
        : colorScheme.surfaceContainerLowest.withValues(alpha: 0.30);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    final surfaceLayer = DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: content,
    );

    final blurred = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surfaceLayer,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppElevation.soft(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: clipContent
          ? blurred
          : ClipRRect(borderRadius: borderRadius, child: blurred),
    );
  }
}
