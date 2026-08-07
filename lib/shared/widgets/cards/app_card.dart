import 'package:flutter/material.dart';

import '../../../core/theme/component_tokens/card_tokens.dart';
import '../../../core/theme/tokens/app_elevation.dart';

/// The canonical surface container for PetConnect AI.
///
/// A themed card with the design system's radius, padding, and soft elevation.
/// Supports an optional tap handler (adds ripple) and a flat/outlined style.
/// All colors come from the active [ColorScheme].
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    this.isOutlined = false,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isOutlined;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final effectivePadding = padding ?? CardTokens.padding;

    final content = Padding(
      padding: effectivePadding,
      child: child,
    );

    final decoration = BoxDecoration(
      color: backgroundColor ?? colorScheme.surfaceContainerLow,
      borderRadius: CardTokens.radius,
      border: isOutlined
          ? Border.all(color: colorScheme.outlineVariant)
          : null,
      boxShadow: isOutlined ? null : AppElevation.card(brightness),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: CardTokens.radius,
          child: Ink(
            decoration: decoration,
            child: content,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: content,
    );
  }
}
