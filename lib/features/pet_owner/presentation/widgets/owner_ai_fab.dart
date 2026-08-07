import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_durations.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';

/// The floating "AI Assistant" action button anchored above the bottom nav on
/// every Pet Owner screen.
///
/// Renders the frozen design's emerald circle with the `auto_awesome` glyph
/// and the seed-tinted `shadow-glow`. A subtle press-scale gives the
/// "Expressive" feel. The glow tint comes from [AppElevation.shadowGlow]
/// (seed primary) so it stays consistent across Light and Dark.
class OwnerAiFab extends StatefulWidget {
  const OwnerAiFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<OwnerAiFab> createState() => _OwnerAiFabState();
}

class _OwnerAiFabState extends State<OwnerAiFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = PortalPalettes.of(AppPortal.petOwner).accent;

    return GestureDetector(
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
            color: accent,
            shape: BoxShape.circle,
            boxShadow: AppElevation.shadowGlow,
          ),
          child: const Icon(
            Icons.auto_awesome,
            // Emerald accent is a fixed brand color; its on-color is white in
            // both themes (the design pairs `bg-emerald-accent` with
            // `text-white` throughout).
            color: Colors.white,
            size: AppIconSizes.lg - 4,
          ),
        ),
      ),
    );
  }
}
