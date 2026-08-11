import 'package:flutter/material.dart';

import '../../../core/theme/component_tokens/chip_tokens.dart';

/// Visual variants for [AppChip].
enum AppChipVariant { filled, outlined }

/// The canonical chip for PetConnect AI.
///
/// Displays a compact label with an optional leading icon or avatar, a delete
/// action, and tap handling. Colors come from the active [ColorScheme].
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.variant = AppChipVariant.filled,
    this.icon,
    this.avatar,
    this.onTap,
    this.onDeleted,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  final String label;
  final AppChipVariant variant;
  final IconData? icon;
  final Widget? avatar;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelWidget = Text(
      label,
      style: textColor != null ? TextStyle(color: textColor) : null,
    );

    if (variant == AppChipVariant.outlined) {
      return RawChip(
        label: labelWidget,
        selected: isSelected,
        backgroundColor: backgroundColor,
        onSelected: onTap != null ? (_) => onTap!() : null,
        avatar: _buildLeading(),
        deleteIcon: onDeleted != null
            ? const Icon(Icons.close, size: ChipTokens.iconSize)
            : null,
        onDeleted: onDeleted,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
        ),
      );
    }

    return FilterChip(
      label: labelWidget,
      selected: isSelected,
      backgroundColor: backgroundColor,
      onSelected: onTap != null ? (_) => onTap!() : null,
      avatar: _buildLeading(),
      deleteIcon: onDeleted != null
          ? const Icon(Icons.close, size: ChipTokens.iconSize)
          : null,
      onDeleted: onDeleted,
    );
  }

  Widget? _buildLeading() {
    if (avatar != null) return avatar;
    if (icon != null) return Icon(icon, size: ChipTokens.iconSize);
    return null;
  }
}
