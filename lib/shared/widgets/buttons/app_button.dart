import 'package:flutter/material.dart';

import '../../../core/theme/component_tokens/button_tokens.dart';

/// Visual variants for [AppButton], mapped to Material 3 button types.
enum AppButtonVariant { filled, tonal, outlined, text }

/// Size options for [AppButton].
enum AppButtonSize { small, medium, large }

/// The canonical button for PetConnect AI.
///
/// Wraps Material 3 buttons with the design system's sizing, an optional
/// leading icon, a loading state, and full-width support. Colors come from the
/// active [ColorScheme] via the button themes in `AppTheme` — nothing is
/// hardcoded here.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  /// Convenience constructor for a filled (primary) button.
  const AppButton.filled({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  }) : variant = AppButtonVariant.filled;

  /// Convenience constructor for an outlined (secondary) button.
  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  }) : variant = AppButtonVariant.outlined;

  /// Convenience constructor for a text button.
  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  }) : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);
    final style = _style();

    final button = switch (variant) {
      AppButtonVariant.filled =>
        FilledButton(onPressed: effectiveOnPressed, style: style, child: child),
      AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.text =>
        TextButton(onPressed: effectiveOnPressed, style: style, child: child),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  ButtonStyle _style() {
    final (padding, height) = switch (size) {
      AppButtonSize.small => (ButtonTokens.paddingSmall, ButtonTokens.heightSmall),
      AppButtonSize.medium => (ButtonTokens.paddingMedium, ButtonTokens.heightMedium),
      AppButtonSize.large => (ButtonTokens.paddingLarge, ButtonTokens.heightLarge),
    };
    return ButtonStyle(
      padding: WidgetStatePropertyAll(padding),
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      final iconSize = switch (size) {
        AppButtonSize.small => ButtonTokens.iconSizeSmall,
        AppButtonSize.medium => ButtonTokens.iconSizeMedium,
        AppButtonSize.large => ButtonTokens.iconSizeLarge,
      };
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      final iconSize = switch (size) {
        AppButtonSize.small => ButtonTokens.iconSizeSmall,
        AppButtonSize.medium => ButtonTokens.iconSizeMedium,
        AppButtonSize.large => ButtonTokens.iconSizeLarge,
      };
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: ButtonTokens.iconGap),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
