/// Shared building blocks for the Pet Owner **Smart Collar** module.
///
/// Renders the recurring pieces of the frozen Stitch collar screens — the
/// glass back-nav bar, device-status stat tiles, the circular activity/metric
/// ring, quick-action tiles, the live-map preview and status pills — so the
/// collar screens compose them instead of duplicating layout. Every color,
/// radius, spacing and type value comes from the design tokens / theme, so one
/// widget tree serves both Light and Dark.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';



/// Builds the frozen collar glass app bar: a back button, a `primary` bold
/// title and optional trailing [actions].
OwnerGlassAppBar collarAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
}) {
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
    actions: actions,
  );
}

/// A compact device-status tile: a leading icon, a small label and a bold
/// value, on a soft surface. Matches the "Location / Battery / Signal" grid.
class CollarStatTile extends StatelessWidget {
  const CollarStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.brCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? scheme.primary, size: AppIconSizes.md),
          AppSpacing.vGapXs,
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A large circular metric ring (steps, battery, goal progress) with a value
/// and caption stacked in the middle. Reused by the dashboard's "Today's
/// Activity" gauge and the activity-monitoring screen.
class CollarMetricRing extends StatelessWidget {
  const CollarMetricRing({
    required this.progress,
    required this.center,
    required this.arcColor,
    this.size = 192,
    this.stroke = 14,
    super.key,
  });

  final double progress;
  final Widget center;
  final Color arcColor;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: scheme.surfaceContainerHighest,
          arcColor: arcColor,
          stroke: stroke,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.arcColor,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color arcColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.track != track ||
      old.stroke != stroke;
}

/// A large tappable quick-action tile: a big icon over a label, on a filled
/// tonal surface. Matches the collar dashboard's 2×2 action grid (Live
/// Tracking, Lost Mode, Geofence, Diagnostics).
class CollarActionTile extends StatelessWidget {
  const CollarActionTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.brCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppIconSizes.xl, color: foreground),
              AppSpacing.vGapSm,
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded live-map preview with interactive vector cartography, pulsing GPS
/// radar pin and geofence overlays. Reused by the dashboard mini-map and tracking screens.
class CollarMapPreview extends StatelessWidget {
  const CollarMapPreview({
    required this.locationLabel,
    this.height = 192,
    this.latitude = 37.7749,
    this.longitude = -122.4194,
    this.petName = 'Buddy',
    this.safeZones = const [],
    this.breadcrumbs = const [],
    this.onTap,
    super.key,
  });

  final String locationLabel;
  final double height;
  final double latitude;
  final double longitude;
  final String petName;
  final List<MapSafeZone> safeZones;
  final List<MapBreadcrumb> breadcrumbs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SmartCollarRealMap(
      height: height,
      locationLabel: locationLabel,
      latitude: latitude,
      longitude: longitude,
      petName: petName,
      safeZones: safeZones,
      breadcrumbs: breadcrumbs,
      onTap: onTap,
    );
  }
}

/// The glass "live" pill with a pulsing primary dot and a location label.
class CollarLivePill extends StatelessWidget {
  const CollarLivePill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.hGapSm,
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}
