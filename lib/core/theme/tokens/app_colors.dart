import 'package:flutter/material.dart';

/// Raw color tokens for the **PetConnect AI Core** design system.
///
/// Values are transcribed verbatim from the frozen Stitch `DESIGN.md`
/// (single source of truth). The Light palette is the master reference.
///
/// The Dark palette is derived using the standard Material 3 light↔dark
/// role mapping, reusing the *exact* tone values the frozen spec already
/// provides for its `inverse-*` and `*-fixed*` roles (e.g. dark `primary`
/// == light `inverse-primary`). This keeps Dark faithful to the frozen
/// tokens rather than inventing new hues; hand-designed Stitch Dark
/// screens remain the visual reference for per-screen reconciliation.
///
/// NEVER reference these directly inside widgets — consume them through
/// [ColorScheme] / [ThemeData] / [Theme.of(context)]. They are exposed
/// only so the theme layer can assemble the schemes.
abstract final class AppColors {
  const AppColors._();

  // ───────────────────────────────────────────────────────────────
  // Seed (shared M3 seed for "PetConnect AI Core", FIDELITY variant)
  // ───────────────────────────────────────────────────────────────
  static const Color seed = Color(0xFF6750A4);

  // ═══════════════════════════════════════════════════════════════
  // LIGHT — master reference (exact from DESIGN.md)
  // ═══════════════════════════════════════════════════════════════
  static const Color lightPrimary = Color(0xFF4F378A);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFF6750A4);
  static const Color lightOnPrimaryContainer = Color(0xFFE0D2FF);

  static const Color lightSecondary = Color(0xFF63597C);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFE1D4FD);
  static const Color lightOnSecondaryContainer = Color(0xFF645A7D);

  static const Color lightTertiary = Color(0xFF765B00);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFC9A74D);
  static const Color lightOnTertiaryContainer = Color(0xFF503D00);

  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF93000A);

  static const Color lightBackground = Color(0xFFFDF7FF);
  static const Color lightOnBackground = Color(0xFF1D1B20);

  static const Color lightSurface = Color(0xFFFDF7FF);
  static const Color lightOnSurface = Color(0xFF1D1B20);
  static const Color lightSurfaceVariant = Color(0xFFE6E0E9);
  static const Color lightOnSurfaceVariant = Color(0xFF494551);

  static const Color lightSurfaceDim = Color(0xFFDED8E0);
  static const Color lightSurfaceBright = Color(0xFFFDF7FF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF8F2FA);
  static const Color lightSurfaceContainer = Color(0xFFF2ECF4);
  static const Color lightSurfaceContainerHigh = Color(0xFFECE6EE);
  static const Color lightSurfaceContainerHighest = Color(0xFFE6E0E9);

  static const Color lightOutline = Color(0xFF7A7582);
  static const Color lightOutlineVariant = Color(0xFFCBC4D2);
  static const Color lightSurfaceTint = Color(0xFF6750A4);
  static const Color lightInverseSurface = Color(0xFF322F35);
  static const Color lightInverseOnSurface = Color(0xFFF5EFF7);
  static const Color lightInversePrimary = Color(0xFFCFBCFF);

  // Fixed accent roles (used by Dark derivation below).
  static const Color primaryFixed = Color(0xFFE9DDFF);
  static const Color primaryFixedDim = Color(0xFFCFBCFF);
  static const Color onPrimaryFixed = Color(0xFF22005D);
  static const Color onPrimaryFixedVariant = Color(0xFF4F378A);
  static const Color secondaryFixed = Color(0xFFE9DDFF);
  static const Color secondaryFixedDim = Color(0xFFCDC0E9);
  static const Color onSecondaryFixed = Color(0xFF1F1635);
  static const Color onSecondaryFixedVariant = Color(0xFF4B4263);
  static const Color tertiaryFixed = Color(0xFFFFDF93);
  static const Color tertiaryFixedDim = Color(0xFFE7C365);
  static const Color onTertiaryFixed = Color(0xFF241A00);
  static const Color onTertiaryFixedVariant = Color(0xFF594400);

  // ═══════════════════════════════════════════════════════════════
  // DARK — derived via M3 light↔dark role mapping, reusing the frozen
  // spec's own inverse/fixed tone values where they map directly.
  // Strategy per DESIGN.md: "Tonal Elevation" — deep hue-tinted
  // surfaces, never pure black.
  // ═══════════════════════════════════════════════════════════════
  static const Color darkPrimary = Color(
    0xFFCFBCFF,
  ); // == light inversePrimary / primaryFixedDim
  static const Color darkOnPrimary = Color(0xFF381E72);
  static const Color darkPrimaryContainer = Color(
    0xFF4F378A,
  ); // == light primary
  static const Color darkOnPrimaryContainer = Color(
    0xFFE9DDFF,
  ); // == light primaryFixed

  static const Color darkSecondary = Color(
    0xFFCDC0E9,
  ); // == light secondaryFixedDim
  static const Color darkOnSecondary = Color(0xFF342B48);
  static const Color darkSecondaryContainer = Color(
    0xFF4B4263,
  ); // == light onSecondaryFixedVariant
  static const Color darkOnSecondaryContainer = Color(
    0xFFE9DDFF,
  ); // == light secondaryFixed

  static const Color darkTertiary = Color(
    0xFFE7C365,
  ); // == light tertiaryFixedDim
  static const Color darkOnTertiary = Color(0xFF3E2E00);
  static const Color darkTertiaryContainer = Color(
    0xFF594400,
  ); // == light onTertiaryFixedVariant
  static const Color darkOnTertiaryContainer = Color(
    0xFFFFDF93,
  ); // == light tertiaryFixed

  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(
    0xFF93000A,
  ); // == light onErrorContainer
  static const Color darkOnErrorContainer = Color(
    0xFFFFDAD6,
  ); // == light errorContainer

  static const Color darkBackground = Color(0xFF141218);
  static const Color darkOnBackground = Color(0xFFE6E0E9);

  static const Color darkSurface = Color(0xFF141218);
  static const Color darkOnSurface = Color(0xFFE6E0E9);
  static const Color darkSurfaceVariant = Color(0xFF49454F);
  static const Color darkOnSurfaceVariant = Color(
    0xFFCBC4D2,
  ); // == light outlineVariant tone family

  static const Color darkSurfaceDim = Color(0xFF141218);
  static const Color darkSurfaceBright = Color(0xFF3B383E);
  static const Color darkSurfaceContainerLowest = Color(0xFF0F0D13);
  static const Color darkSurfaceContainerLow = Color(0xFF1D1B20);
  static const Color darkSurfaceContainer = Color(0xFF211F26);
  static const Color darkSurfaceContainerHigh = Color(0xFF2B2930);
  static const Color darkSurfaceContainerHighest = Color(0xFF36343B);

  static const Color darkOutline = Color(0xFF958E99);
  static const Color darkOutlineVariant = Color(
    0xFF494551,
  ); // == light onSurfaceVariant tone
  static const Color darkSurfaceTint = Color(0xFFCFBCFF);
  static const Color darkInverseSurface = Color(0xFFE6E0E9);
  static const Color darkInverseOnSurface = Color(0xFF322F35);
  static const Color darkInversePrimary = Color(0xFF4F378A);

  // ═══════════════════════════════════════════════════════════════
  // Neutral primitives & functional overlays
  // ═══════════════════════════════════════════════════════════════
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  /// Card hairline border — `#00000010` per DESIGN.md components spec.
  static const Color cardBorderLight = Color(0x1A000000); // 10% black
  static const Color cardBorderDark = Color(0x1FFFFFFF); // ~12% white

  /// Divider — low-contrast neutral, 10% opacity (DESIGN.md).
  static const Color dividerLight = Color(0x1A000000);
  static const Color dividerDark = Color(0x1FFFFFFF);

  /// Interactive/focus overlay — 12% of primary (DESIGN.md).
  static Color focusOverlayLight = lightPrimary.withValues(alpha: 0.12);
  static Color focusOverlayDark = darkPrimary.withValues(alpha: 0.12);

  /// Glassmorphic top-bar / bottom-sheet surface — 60% translucent
  /// surface with `backdrop-filter: blur(20px)` (applied in the widget).
  static Color glassLight = lightSurface.withValues(alpha: 0.60);
  static Color glassDark = darkSurface.withValues(alpha: 0.60);

  // ═══════════════════════════════════════════════════════════════
  // Semantic status colors (shared across portals)
  // ═══════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFB6F2B8);
  static const Color warning = Color(0xFF9A6700);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE08A);
  static const Color info = Color(0xFF2A6FB0);
  static const Color infoContainer = Color(0xFFCDE5FF);
}
