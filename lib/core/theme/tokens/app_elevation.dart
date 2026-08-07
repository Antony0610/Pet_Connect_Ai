import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation & shadow tokens for the **PetConnect AI Core** design system.
///
/// Per frozen `DESIGN.md`: the system prefers **flat, tonal elevation** with
/// soft, low-spread shadows. Cards sit at a low resting elevation with a
/// subtle shadow; overlays (menus, sheets, dialogs) use higher levels.
///
/// The `level*` doubles are Material 3 elevation steps (dp). The `shadow*`
/// lists are the design's custom soft shadows for use where an explicit
/// [BoxShadow] is needed (e.g. glassmorphic surfaces, custom cards).
abstract final class AppElevation {
  const AppElevation._();

  /// 0dp — flush surfaces, flat cards on tinted backgrounds.
  static const double level0 = 0;

  /// 1dp — resting cards.
  static const double level1 = 1;

  /// 3dp — raised cards, search bars.
  static const double level2 = 3;

  /// 6dp — FAB, contextual menus.
  static const double level3 = 6;

  /// 8dp — navigation drawer, modal sheets.
  static const double level4 = 8;

  /// 12dp — dialogs.
  static const double level5 = 12;

  // ── Soft custom shadows (design "low-spread" style) ────────────

  /// Resting card shadow — soft, tight, low opacity.
  static const List<BoxShadow> shadowCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000), // ~8% black
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Raised / hover shadow.
  static const List<BoxShadow> shadowRaised = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000), // ~12% black
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Overlay shadow — menus, sheets, popovers.
  static const List<BoxShadow> shadowOverlay = <BoxShadow>[
    BoxShadow(
      color: Color(0x29000000), // ~16% black
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  /// Dark-mode card shadow — darker, since tonal surfaces need depth.
  static const List<BoxShadow> shadowCardDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000), // ~25% black
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  /// Returns the correct card shadow for the given [brightness].
  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.dark ? shadowCardDark : shadowCard;

  /// Surface tint used for M3 tonal elevation (light).
  static const Color surfaceTintLight = AppColors.lightSurfaceTint;

  /// Surface tint used for M3 tonal elevation (dark).
  static const Color surfaceTintDark = AppColors.darkSurfaceTint;
}
