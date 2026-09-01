import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
    this.centerOffset = Offset.zero,
    this.centerLatLng,
    this.color = AppColors.success,
  });

  final String id;
  final String name;
  final double radiusMeters;
  final Offset centerOffset;
  final LatLng? centerLatLng;
  final Color color;
}

/// Waypoint on the pet's movement path.
class MapBreadcrumb {
  const MapBreadcrumb({
    this.offset = Offset.zero,
    this.latLng,
    required this.time,
    required this.speedKmh,
  });

  final Offset offset;
  final LatLng? latLng;
  final String time;
  final double speedKmh;
}

/// **Smart Collar Real Interactive Map Engine**
///
/// Powered by **OpenStreetMap (100% Free, Zero API Keys, Zero Quotas)**.
/// Features:
/// - Real live tile streaming (OSM Standard, ArcGIS Satellite, CartoDB Dark Matter)
/// - Live pulsing GPS radar marker
/// - Real geofence boundary rings (with exact metric radius)
/// - Historical movement breadcrumb polyline
/// - Interactive gestures (pinch-to-zoom, pan, double-tap zoom)
/// - Zoom, recenter, layer-switching, and telemetry overlays
class SmartCollarRealMap extends StatefulWidget {
  const SmartCollarRealMap({
    super.key,
    this.height = 320,
    this.locationLabel = 'Live GPS Telemetry',
    this.latitude = 10.2740,
    this.longitude = 76.3216,
    this.petName = 'Companion',
    this.safeZones = const [],
    this.breadcrumbs = const [],
    this.showControls = true,
    this.isInteractive = true,
    this.onTap,
    this.onMapTap,
    this.isEditMode = false,
    this.editModeMessage,
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
  final ValueChanged<LatLng>? onMapTap;
  final bool isEditMode;
  final String? editModeMessage;

  @override
  State<SmartCollarRealMap> createState() => _SmartCollarRealMapState();
}

class _SmartCollarRealMapState extends State<SmartCollarRealMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final MapController _mapController = MapController();

  MapLayerStyle _currentLayer = MapLayerStyle.street;
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
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrl(MapLayerStyle style) {
    switch (style) {
      case MapLayerStyle.satellite:
        // Free global satellite imagery provided by Esri ArcGIS
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerStyle.darkNight:
        // Free Dark Matter raster tiles by CartoDB
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapLayerStyle.street:
        // Free standard OpenStreetMap tiles
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _zoomIn() {
    final current = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (current + 1.0).clamp(3.0, 18.0),
    );
  }

  void _zoomOut() {
    final current = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (current - 1.0).clamp(3.0, 18.0),
    );
  }

  void _recenter() {
    _mapController.move(LatLng(widget.latitude, widget.longitude), 15.5);
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

    final petCenter = LatLng(widget.latitude, widget.longitude);

    // Build breadcrumbs path
    final breadcrumbPoints = widget.breadcrumbs.isNotEmpty
        ? widget.breadcrumbs.map((b) {
            return b.latLng ??
                LatLng(
                  widget.latitude + (b.offset.dy * 0.00004),
                  widget.longitude + (b.offset.dx * 0.00004),
                );
          }).toList()
        : [
            LatLng(widget.latitude - 0.0015, widget.longitude - 0.0018),
            LatLng(widget.latitude - 0.0009, widget.longitude - 0.0008),
            LatLng(widget.latitude - 0.0003, widget.longitude - 0.0002),
            petCenter,
          ];

    // Build safe zones
    final activeSafeZones = widget.safeZones.isNotEmpty
        ? widget.safeZones
        : [
            MapSafeZone(
              id: 'home_base',
              name: 'Home Perimeter (150m)',
              radiusMeters: 150,
              centerLatLng: petCenter,
              color: AppColors.success,
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
            // ── Real OpenStreetMap Tile Canvas ─────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: petCenter,
                initialZoom: 15.5,
                minZoom: 3.0,
                maxZoom: 18.5,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
                onTap: (_, point) {
                  widget.onMapTap?.call(point);
                  widget.onTap?.call();
                },
              ),
              children: [
                // 1. OpenStreetMap Tile Layer
                TileLayer(
                  urlTemplate: _getTileUrl(_currentLayer),
                  userAgentPackageName: 'com.petconnect.ai',
                  maxZoom: 19,
                ),

                // 2. Safe Zone Geofence Circles
                if (_showGeofences)
                  CircleLayer(
                    circles: activeSafeZones.map((zone) {
                      final center = zone.centerLatLng ??
                          LatLng(
                            widget.latitude + (zone.centerOffset.dy * 0.00004),
                            widget.longitude + (zone.centerOffset.dx * 0.00004),
                          );
                      return CircleMarker(
                        point: center,
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color: zone.color.withValues(alpha: 0.22),
                        borderColor: zone.color,
                        borderStrokeWidth: 2.0,
                      );
                    }).toList(),
                  ),

                // 3. Historical Breadcrumbs Path
                if (_showBreadcrumbs && breadcrumbPoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: breadcrumbPoints,
                        color: scheme.primary.withValues(alpha: 0.85),
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),

                // 4. Markers Layer (Pulsing Pet Marker & Safe Zone Icons)
                MarkerLayer(
                  markers: [
                    // Safe Zone Badges
                    ...activeSafeZones.map((zone) {
                      final center = zone.centerLatLng ??
                          LatLng(
                            widget.latitude + (zone.centerOffset.dy * 0.00004),
                            widget.longitude + (zone.centerOffset.dx * 0.00004),
                          );
                      return Marker(
                        point: center,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: zone.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield, color: Colors.white, size: 14),
                        ),
                      );
                    }),

                    // Live Pulsing GPS Pet Marker
                    Marker(
                      point: petCenter,
                      width: 64,
                      height: 64,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer expanding ripple
                              Container(
                                width: 32 + (pulse * 28),
                                height: 32 + (pulse * 28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: (1.0 - pulse) * 0.45),
                                ),
                              ),
                              // Halo
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.25),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              // Core Pin
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.pets, color: Colors.white, size: 15),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Floating Edit Mode Banner ──────────────────────────────────
            if (widget.isEditMode)
              Positioned(
                top: AppSpacing.sm,
                left: 70,
                right: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadius.brPill,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.editModeMessage ?? 'Tap map to relocate safe zone',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Top-Left: Map Layer & Telemetry Indicator ──────────────────
            if (!widget.isEditMode)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.88),
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
                            ? 'OSM STREET'
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
                      tooltip: 'Switch Map Style (OSM / Satellite / Night)',
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
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: iconColor ?? scheme.onSurface),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
