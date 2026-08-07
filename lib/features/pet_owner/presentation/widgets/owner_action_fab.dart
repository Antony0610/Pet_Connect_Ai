import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_durations.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// A floating primary action button used for screen-level "create" actions
/// (e.g. **Add Pet** on the My Pets list).
///
/// Renders the frozen design's rounded-square primary button: a `bg-primary`
/// tile with a 16px radius, the seed-tinted `shadow-glow` and a press-scale
/// for the "Expressive" feel. Colors come from the active [ColorScheme] so a
/// single widget tree serves Light and Dark. Pair with
/// [OwnerScaffold.floatingActionButton] so it lifts above the glass nav bar.
class OwnerActionFab extends StatefulWidget {
  const OwnerActionFab({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<OwnerActionFab> createState() => _OwnerActionFabState();
}

class _OwnerActionFabState extends State<OwnerActionFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: AppDurations.short3,
        curve: AppDurations.standard,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: AppRadius.brCard,
            boxShadow: AppElevation.shadowGlow,
          ),
          child: Icon(
            widget.icon,
            color: scheme.onPrimary,
            size: AppIconSizes.lg,
          ),
        ),
      ),
    );

    final tooltip = widget.tooltip;
    return tooltip == null
        ? button
        : Tooltip(message: tooltip, child: button);
  }
}
