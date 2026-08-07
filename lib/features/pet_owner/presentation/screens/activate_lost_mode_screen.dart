import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_durations.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// The Pet Owner **Activate Lost Mode** confirmation.
///
/// A faithful Flutter rendering of the frozen Stitch "Activate Lost Mode"
/// (Light master): a full-bleed calming neighbourhood map dimmed to 40%, a
/// pulsing error marker fixed near the top, and a floating glass confirmation
/// sheet that slides up from the bottom. The sheet explains what activating
/// Lost Mode does (four action rows) and offers an error-filled "Activate Lost
/// Mode" primary and an outlined "Cancel".
///
/// The sheet docks to the bottom on mobile (`rounded-t-[32px]`) and floats
/// centred on wider screens (`rounded-[32px]`, `md:justify-center`). Every
/// color, radius, spacing and elevation comes from the theme / design tokens so
/// this one widget tree serves both Light and Dark.
class ActivateLostModeScreen extends StatelessWidget {
  const ActivateLostModeScreen({super.key});

  /// The design's `md:` breakpoint — the sheet floats centred at/above this.
  static const double _floatingWidth = 768;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isWide = context.screenWidth >= _floatingWidth;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // ── Map background (dimmed) ───────────────────────────────
          const Positioned.fill(child: _MapBackground()),

          // ── Central focus marker (pulse) ──────────────────────────
          const Align(
            alignment: Alignment(0, -0.4),
            child: _PulseMarker(),
          ),

          // ── Bottom sheet / confirmation card ──────────────────────
          Align(
            alignment: isWide ? Alignment.center : Alignment.bottomCenter,
            child: _ConfirmationSheet(isWide: isWide),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Map background
// ═══════════════════════════════════════════════════════════════════

/// The soft, illustrative neighbourhood map shown behind everything at 40%
/// opacity. Falls back to a calm surface tint if the image can't load.
class _MapBackground extends StatelessWidget {
  const _MapBackground();

  static const String _mapUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ2C688crIoEbkyFkJJIDeN4PFyxeyUqeRk1Z8kQgZ2nzQT9EBQmQq-5rWnpRRJ6LWpSIYZ3ExwgW0YCqzeAvzPhTT0Z4BYbLKqWUjEhcFHtoIrkLG7ibzguH5xKv6UR6B03PqO2QpVoH0pQRi6iW2278PsbDgGoNB1F0PR9iyZqQoRH4CHrFGkuCHPhsZANmWI9zsx0NNIRMFBlgw93ivDla5neQ8kiIjXMt6TSCEwQpMYUT1_v8PrQ';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Opacity(
      opacity: 0.40,
      child: Image.network(
        _mapUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surfaceContainer),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Pulsing focus marker
// ═══════════════════════════════════════════════════════════════════

/// The 64px error marker with an expanding "pulse ring" and a solid 48px error
/// disc carrying a white `pets` glyph.
class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  static const double _outer = 64;
  static const double _inner = 48;

  /// The Stitch `pulse-ring` keyframe runs on a 2s loop.
  static const Duration _pulse = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: _outer,
      height: _outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding, fading ring — bg-error/20 pulse-ring.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // scale 0.95 → 1.0 → 0.95, opacity 0.5 → 0 → 0 (Stitch keyframe).
              final t = _controller.value;
              final scale = 0.95 + 0.05 * (t < 0.7 ? t / 0.7 : 1);
              final opacity = t < 0.7 ? 0.5 * (1 - t / 0.7) : 0.0;
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error.withValues(alpha: 0.20),
              ),
            ),
          ),
          // Solid marker disc.
          Container(
            width: _inner,
            height: _inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.error,
              boxShadow: AppElevation.shadowSoft,
            ),
            child: Icon(
              Icons.pets,
              size: AppIconSizes.lg,
              color: scheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Confirmation sheet
// ═══════════════════════════════════════════════════════════════════

/// The floating glass confirmation card that slides up on entry.
class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({required this.isWide});

  final bool isWide;

  /// The design's `max-w-md` cap on the floating sheet.
  static const double _maxWidth = 448;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // rounded-t-[32px] docked to the bottom on mobile; rounded-[32px] floating.
    final borderRadius = isWide ? AppRadius.brModal : AppRadius.brModalTop;
    // p-margin-mobile (20) / md:p-margin-desktop (40), with pb-10 (40) bottom.
    final pad = isWide ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

    final sheet = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.90),
            borderRadius: borderRadius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.20),
            ),
            boxShadow: AppElevation.shadowOverlay,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHeader(),
                AppSpacing.vGapLg,
                const _ActionList(),
                AppSpacing.vGapLg,
                _SheetActions(
                  onActivate: () => context.showSnackbar(
                    'Lost Mode activation is coming soon.',
                  ),
                  onCancel: () => context.pop<void>(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // max-w-md.
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: _SlideUp(child: sheet),
      ),
    );
  }
}

/// Centred title + reassuring subtitle.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Activate Lost Mode?',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapSm,
        Text(
          "We'll help you find Buddy every step of the way.",
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Action list
// ═══════════════════════════════════════════════════════════════════

/// The framed list of the four things Lost Mode does, with hairline dividers.
class _ActionList extends StatelessWidget {
  const _ActionList();

  static const List<_LostAction> _actions = [
    _LostAction(
      icon: Icons.satellite_alt,
      title: 'Higher GPS frequency (30s)',
      subtitle: 'Updates location more often',
    ),
    _LostAction(
      icon: Icons.my_location,
      title: 'Real-time tracking',
      subtitle: 'Live movement on the map',
    ),
    _LostAction(
      icon: Icons.notifications_active,
      title: 'Volunteer notification',
      subtitle: 'Alerts nearby rescue team',
    ),
    _LostAction(
      icon: Icons.campaign,
      title: 'Community alert',
      subtitle: 'Broadcasts to users in area',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final rows = <Widget>[];
    for (var i = 0; i < _actions.length; i++) {
      if (i > 0) rows.add(const _ActionDivider());
      rows.add(_ActionRow(action: _actions[i]));
    }

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.10),
        ),
        boxShadow: AppElevation.shadowSoft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

/// One action row: a soft error-container icon chip, title and subtitle.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final _LostAction action;

  static const double _chip = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Container(
          width: _chip,
          height: _chip,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.errorContainer,
          ),
          child: Icon(
            action.icon,
            size: AppIconSizes.md,
            color: scheme.onErrorContainer,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.title,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                action.subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The hairline between action rows, indented to align under the text (the
/// design's `ml-14` = 56px = 40px chip + 16px gap).
class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  static const double _indent = 56;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.only(left: _indent),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.20),
          ),
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sheet actions
// ═══════════════════════════════════════════════════════════════════

/// The stacked primary (error-filled) and secondary (outlined) buttons.
class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.onActivate, required this.onCancel});

  final VoidCallback onActivate;
  final VoidCallback onCancel;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: FilledButton.icon(
            onPressed: onActivate,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brPill,
              ),
            ),
            icon: const Icon(Icons.warning_amber_rounded, size: AppIconSizes.sm),
            label: const Text('Activate Lost Mode'),
          ),
        ),
        AppSpacing.vGapSm,
        SizedBox(
          height: _height,
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outline),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brPill,
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Entrance animation
// ═══════════════════════════════════════════════════════════════════

/// Slides its child up from the bottom while fading in, mirroring the design's
/// `slideUp 0.4s ease-out` sheet entrance.
class _SlideUp extends StatefulWidget {
  const _SlideUp({required this.child});

  final Widget child;

  @override
  State<_SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<_SlideUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.medium4,
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Model
// ═══════════════════════════════════════════════════════════════════

/// One row in the Lost Mode action list.
class _LostAction {
  const _LostAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
