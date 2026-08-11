import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/component_tokens/button_tokens.dart';

/// Visual variants for [AppButton], mapped to Material 3 button types.
enum AppButtonVariant { filled, tonal, outlined, text }

/// Size options for [AppButton].
enum AppButtonSize { small, medium, large }

/// The canonical button for PetConnect AI.
class AppButton extends StatelessWidget {
  const AppButton({
    this.label,
    this.text,
    this.child,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.borderRadius,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    super.key,
  });

  /// Convenience constructor for a filled (primary) button.
  const AppButton.filled({
    this.label,
    this.text,
    this.child,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.borderRadius,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    super.key,
  }) : variant = AppButtonVariant.filled;

  /// Convenience constructor for an outlined (secondary) button.
  const AppButton.outlined({
    this.label,
    this.text,
    this.child,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.borderRadius,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    super.key,
  }) : variant = AppButtonVariant.outlined;

  /// Convenience constructor for a text button.
  const AppButton.text({
    this.label,
    this.text,
    this.child,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.borderRadius,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    super.key,
  }) : variant = AppButtonVariant.text;

  final String? label;
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  String _getEffectiveLabel() {
    if (label != null && label!.isNotEmpty) return label!;
    if (text != null && text!.isNotEmpty) return text!;
    if (child is Text) {
      final textWidget = child as Text;
      return textWidget.data ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final buttonChild = _buildChild(context);
    final style = _style();

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: buttonChild,
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        style: style,
        child: buttonChild,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: buttonChild,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: buttonChild,
      ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  ButtonStyle _style() {
    final (padding, defaultHeight) = switch (size) {
      AppButtonSize.small => (
        ButtonTokens.paddingSmall,
        ButtonTokens.heightSmall,
      ),
      AppButtonSize.medium => (
        ButtonTokens.paddingMedium,
        ButtonTokens.heightMedium,
      ),
      AppButtonSize.large => (
        ButtonTokens.paddingLarge,
        ButtonTokens.heightLarge,
      ),
    };
    return ButtonStyle(
      padding: WidgetStatePropertyAll(padding),
      minimumSize: WidgetStatePropertyAll(Size(0, height ?? defaultHeight)),
      backgroundColor: backgroundColor != null
          ? WidgetStatePropertyAll(backgroundColor)
          : null,
      foregroundColor: textColor != null
          ? WidgetStatePropertyAll(textColor)
          : null,
      shape: borderRadius == null
          ? null
          : WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: borderRadius!),
            ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 18.0,
        height: 18.0,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final effectiveLabel = _getEffectiveLabel();
    final labelWidget = child is Text
        ? (child!)
        : Text(effectiveLabel, overflow: TextOverflow.ellipsis);

    if (icon == null) {
      return labelWidget;
    }

    final iconWidget = Icon(icon, size: ButtonTokens.iconSizeMedium);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAlignment == IconAlignment.start
          ? [iconWidget, const SizedBox(width: 8), labelWidget]
          : [labelWidget, const SizedBox(width: 8), iconWidget],
    );
  }
}
