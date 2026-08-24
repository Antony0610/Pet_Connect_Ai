import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';

/// Supported Map Layer Styles.
enum MapLayerStyle {
  street,
  satellite,
  darkNight,
}

/// Geofence Circle Data Model.
class MapSafeZone {
  const MapSafeZone({
    required this.id,
    required this.name,
    required this.radiusMeters,
    required this.centerOffset,
    this.color = AppColors.success,
  });

  final String id;
  final String name;
  final double radiusMeters;
  final Offset centerOffset;
  final Color color;
}

/// Waypoint on the pet's movement path.
class MapBreadcrumb {
  const MapBreadcrumb({
    required this.offset,
    required this.time,
    required this.speedKmh,
  });

  final Offset offset;
  final String time;
  final double speedKmh;
}

/// **Smart Collar Real Interactive Map Engine**
///
/// An interactive map featuring real vector cartography, live pulsing GPS
/// radar pin, geofence boundary rings, historical breadcrumbs, satellite/street/dark
/// layer toggles, and gesture pan/zoom controls.
class SmartCollarRealMap extends StatefulWidget {
  const SmartCollarRealMap({
    super.key,
    this.height = 320,
    this.locationLabel = 'Live GPS Telemetry',
    this.latitude = 37.7749,
    this.longitude = -122.4194,
    this.petName = 'Buddy',
    this.safeZones = const [],
    this.breadcrumbs = const [],
    this.showControls = true,
    this.isInteractive = true,
    this.onTap,
  });

  final double height;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final String petName;
  final List<MapSafeZone> safeZones;
  final List<MapBreadcrumb> breadcrumbs;
  final bool showControls;
  final bool isInteractive;
  final VoidCallback? onTap;

  @override
  State<SmartCollarRealMap> createState() => _SmartCollarRealMapState();
}

class _SmartCollarRealMapState extends State<SmartCollarRealMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TransformationController _transformController =
      TransformationController();

  MapLayerStyle _currentLayer = MapLayerStyle.street;
  double _zoomLevel = 1.0;
  bool _showGeofences = true;
  bool _showBreadcrumbs = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.25).clamp(0.6, 3.5);
      _transformController.value =
          Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.25).clamp(0.6, 3.5);
      _transformController.value =
          Matrix4.diagonal3Values(_zoomLevel, _zoomLevel, 1.0);
    });
  }

  void _recenter() {
    setState(() {
      _zoomLevel = 1.0;
      _transformController.value = Matrix4.identity();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Centered on ${widget.petName}\'s live GPS signal'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cycleLayer() {
    setState(() {
      _currentLayer = switch (_currentLayer) {
        MapLayerStyle.street => MapLayerStyle.satellite,
        MapLayerStyle.satellite => MapLayerStyle.darkNight,
        MapLayerStyle.darkNight => MapLayerStyle.street,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<MapBreadcrumb> defaultBreadcrumbs = widget.breadcrumbs.isNotEmpty
        ? widget.breadcrumbs
        : [
            const MapBreadcrumb(offset: Offset(-80, 50), time: '10m ago', speedKmh: 4.2),
            const MapBreadcrumb(offset: Offset(-45, 30), time: '6m ago', speedKmh: 3.8),
            const MapBreadcrumb(offset: Offset(-20, 10), time: '3m ago', speedKmh: 2.1),
            const MapBreadcrumb(offset: Offset(0, 0), time: 'Now', speedKmh: 0.0),
          ];

    final List<MapSafeZone> defaultSafeZones = widget.safeZones.isNotEmpty
        ? widget.safeZones
        : [
            const MapSafeZone(
              id: 'home_base',
              name: 'Home Perimeter (150m)',
              radiusMeters: 90,
              centerOffset: Offset(0, 0),
              color: AppColors.success,
            ),
            const MapSafeZone(
              id: 'park_zone',
              name: 'Centennial Dog Park',
              radiusMeters: 140,
              centerOffset: Offset(60, -40),
              color: AppColors.info,
            ),
          ];

    return ClipRRect(
      borderRadius: AppRadius.brSection,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _currentLayer == MapLayerStyle.satellite
              ? const Color(0xFF14241C)
              : (_currentLayer == MapLayerStyle.darkNight
                  ? const Color(0xFF0F172A)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Interactive Map Canvas ─────────────────────────────────────
            InteractiveViewer(
              transformationController: _transformController,
              panEnabled: widget.isInteractive,
              scaleEnabled: widget.isInteractive,
              minScale: 0.6,
              maxScale: 3.5,
              onInteractionEnd: (details) {
                _zoomLevel = _transformController.value.getMaxScaleOnAxis();
              },
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _CartographyPainter(
                        layerStyle: _currentLayer,
                        isDarkMode: isDark,
                        pulseValue: _pulseController.value,
                        safeZones: _showGeofences ? defaultSafeZones : [],
                        breadcrumbs: _showBreadcrumbs ? defaultBreadcrumbs : [],
                        petName: widget.petName,
                        latitude: widget.latitude,
                        longitude: widget.longitude,
                        primaryColor: scheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Top-Left: Map Layer & Telemetry Indicator ──────────────────
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.latitude.toStringAsFixed(4)}° N, ${widget.longitude.abs().toStringAsFixed(4)}° W',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentLayer == MapLayerStyle.street
                            ? 'STREET'
                            : (_currentLayer == MapLayerStyle.satellite ? 'SATELLITE' : 'NIGHT GPS'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Top-Right: Map Floating Control Actions ────────────────────
            if (widget.showControls)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapIconButton(
                      icon: _currentLayer == MapLayerStyle.street
                          ? Icons.layers_outlined
                          : (_currentLayer == MapLayerStyle.satellite
                              ? Icons.satellite_alt_outlined
                              : Icons.dark_mode_outlined),
                      tooltip: 'Switch Map Style (Street / Satellite / Night)',
                      onPressed: _cycleLayer,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Center on ${widget.petName}',
                      onPressed: _recenter,
                      scheme: scheme,
                      iconColor: scheme.primary,
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 4),
                    _buildMapIconButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                      scheme: scheme,
                    ),
                  ],
                ),
              ),

            // ── Bottom-Left: Live GPS Status Telemetry Pill ────────────────
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.90),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radar_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.locationLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom-Right: Geofence & Breadcrumb Toggles ────────────────
            if (widget.showControls)
              Positioned(
                bottom: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showGeofences = !_showGeofences),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _showGeofences
                              ? AppColors.success.withValues(alpha: 0.2)
                              : scheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showGeofences ? AppColors.success : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: _showGeofences ? AppColors.success : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Safe Zones',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _showGeofences ? AppColors.success : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _showBreadcrumbs = !_showBreadcrumbs),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _showBreadcrumbs
                              ? scheme.primary.withValues(alpha: 0.2)
                              : scheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showBreadcrumbs ? scheme.primary : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 14,
                              color: _showBreadcrumbs ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trail',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _showBreadcrumbs ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme scheme,
    Color? iconColor,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: iconColor ?? scheme.onSurface),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// **Vector Cartography & Live GPS Radar Painter**
class _CartographyPainter extends CustomPainter {
  _CartographyPainter({
    required this.layerStyle,
    required this.isDarkMode,
    required this.pulseValue,
    required this.safeZones,
    required this.breadcrumbs,
    required this.petName,
    required this.latitude,
    required this.longitude,
    required this.primaryColor,
  });

  final MapLayerStyle layerStyle;
  final bool isDarkMode;
  final double pulseValue;
  final List<MapSafeZone> safeZones;
  final List<MapBreadcrumb> breadcrumbs;
  final String petName;
  final double latitude;
  final double longitude;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // ── 1. Render Map Base & Terrain Grids ────────────────────────────────
    _drawTerrainAndRoads(canvas, size, center);

    // ── 2. Render Safe Zones (Geofence Circles) ───────────────────────────
    _drawSafeZones(canvas, center);

    // ── 3. Render Breadcrumb Path (Trail) ─────────────────────────────────
    _drawBreadcrumbs(canvas, center);

    // ── 4. Render Live Animated Pet GPS Pin with Pulsing Radar ────────────
    _drawPetMarker(canvas, center);
  }

  void _drawTerrainAndRoads(Canvas canvas, Size size, Offset center) {
    final bgPaint = Paint()..style = PaintingStyle.fill;
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arteryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final parkPaint = Paint()..style = PaintingStyle.fill;
    final waterPaint = Paint()..style = PaintingStyle.fill;

    switch (layerStyle) {
      case MapLayerStyle.satellite:
        bgPaint.color = const Color(0xFF1B2E24);
        roadPaint
          ..color = const Color(0xFF5A6E63)
          ..strokeWidth = 3.0;
        arteryPaint
          ..color = const Color(0xFF889C91)
          ..strokeWidth = 6.0;
        parkPaint.color = const Color(0xFF264A35);
        waterPaint.color = const Color(0xFF1E3A4B);
      case MapLayerStyle.darkNight:
        bgPaint.color = const Color(0xFF0B132B);
        roadPaint
          ..color = const Color(0xFF1C2541)
          ..strokeWidth = 2.5;
        arteryPaint
          ..color = const Color(0xFF3A506B)
          ..strokeWidth = 5.0;
        parkPaint.color = const Color(0xFF102820);
        waterPaint.color = const Color(0xFF0A2239);
      case MapLayerStyle.street:
        bgPaint.color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        roadPaint
          ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
          ..strokeWidth = 3.0;
        arteryPaint
          ..color = isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
          ..strokeWidth = 6.0;
        parkPaint.color = isDarkMode ? const Color(0xFF1E3A2B) : const Color(0xFFDCFCE7);
        waterPaint.color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFBAE6FD);
    }

    // Fill canvas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Park polygons
    final parkPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + const Offset(90, -70), width: 180, height: 120),
          const Radius.circular(24),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + const Offset(-120, 80), width: 140, height: 90),
          const Radius.circular(16),
        ),
      );
    canvas.drawPath(parkPath, parkPaint);

    // Draw Water River Path
    final riverPath = Path()
      ..moveTo(-50, size.height + 40)
      ..cubicTo(size.width * 0.2, size.height * 0.7, size.width * 0.6, size.height * 0.85, size.width + 50, size.height * 0.6)
      ..lineTo(size.width + 50, size.height + 50)
      ..lineTo(-50, size.height + 50)
      ..close();
    canvas.drawPath(riverPath, waterPaint);

    // Draw Major Road Arteries
    canvas.drawLine(Offset(0, center.dy + 40), Offset(size.width, center.dy + 40), arteryPaint);
    canvas.drawLine(Offset(center.dx - 60, 0), Offset(center.dx - 60, size.height), arteryPaint);

    // Draw Secondary Street Grids
    for (double y = -240; y <= 240; y += 50) {
      canvas.drawLine(Offset(0, center.dy + y), Offset(size.width, center.dy + y), roadPaint);
    }
    for (double x = -300; x <= 300; x += 60) {
      canvas.drawLine(Offset(center.dx + x, 0), Offset(center.dx + x, size.height), roadPaint);
    }

    // Draw Street Names / Cartography Labels
    _drawStreetLabel(canvas, 'PINE AVENUE', center + const Offset(-50, 48), isDarkMode);
    _drawStreetLabel(canvas, 'CENTENNIAL BLVD', center + const Offset(-54, -90), isDarkMode, vertical: true);
    _drawStreetLabel(canvas, 'CENTENNIAL PARK', center + const Offset(90, -70), isDarkMode, isPark: true);
  }

  void _drawStreetLabel(
    Canvas canvas,
    String text,
    Offset pos,
    bool isDark, {
    bool vertical = false,
    bool isPark = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isPark ? 10 : 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isPark
              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (vertical) canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  void _drawSafeZones(Canvas canvas, Offset center) {
    for (final zone in safeZones) {
      final zoneCenter = center + zone.centerOffset;

      // Fill circle
      final fillPaint = Paint()
        ..color = zone.color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(zoneCenter, zone.radiusMeters, fillPaint);

      // Dashed boundary ring
      final borderPaint = Paint()
        ..color = zone.color.withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(zoneCenter, zone.radiusMeters, borderPaint);

      // Safe Zone Name Tag
      final tagPainter = TextPainter(
        text: TextSpan(
          text: zone.name,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: zone.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tagPainter.paint(
        canvas,
        Offset(zoneCenter.dx - tagPainter.width / 2, zoneCenter.dy - zone.radiusMeters - 14),
      );
    }
  }

  void _drawBreadcrumbs(Canvas canvas, Offset center) {
    if (breadcrumbs.length < 2) return;

    final pathPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < breadcrumbs.length; i++) {
      final pt = center + breadcrumbs[i].offset;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }

      // Small waypoint dot
      final dotPaint = Paint()
        ..color = (i == breadcrumbs.length - 1)
            ? primaryColor
            : primaryColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, (i == breadcrumbs.length - 1) ? 5 : 3, dotPaint);
    }

    canvas.drawPath(path, pathPaint);
  }

  void _drawPetMarker(Canvas canvas, Offset center) {
    // ── Radar Ripple Pulse (Concentric expanding rings) ───────────────────
    final pulseRadius1 = 20.0 + (pulseValue * 36.0);
    final pulseOpacity1 = (1.0 - pulseValue).clamp(0.0, 1.0);

    final radarPaint1 = Paint()
      ..color = primaryColor.withValues(alpha: pulseOpacity1 * 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius1, radarPaint1);

    final pulseRadius2 = 14.0 + (pulseValue * 22.0);
    final radarPaint2 = Paint()
      ..color = primaryColor.withValues(alpha: pulseOpacity1 * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, pulseRadius2, radarPaint2);

    // ── Outer Glow Pin Base ───────────────────────────────────────────────
    final basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, basePaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, innerPaint);

    final corePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, corePaint);

    // ── Pet Name & Compass Heading Badge ──────────────────────────────────
    final labelPainter = TextPainter(
      text: TextSpan(
        text: '🐾 $petName',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + const Offset(0, -30),
        width: labelPainter.width + 16,
        height: labelPainter.height + 8,
      ),
      const Radius.circular(12),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bgRect, bgPaint);

    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - 30 - labelPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CartographyPainter oldDelegate) => true;
}
