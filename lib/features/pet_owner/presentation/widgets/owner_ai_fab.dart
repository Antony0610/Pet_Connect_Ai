import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_durations.dart';
import 'package:petconnect_ai/core/theme/tokens/app_elevation.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';

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

    return AnimatedScale(
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
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPressed();
            },
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: AppIconSizes.lg - 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
