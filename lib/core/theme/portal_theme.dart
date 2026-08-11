import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_theme.dart';
import 'tokens/app_colors.dart';

/// The four product portals of PetConnect AI. Each portal shares the "Core"
/// design system (layout, type, spacing, components) but carries its own
/// accent identity layered over the shared M3 seed.
enum AppPortal { petOwner, veterinarian, volunteerRescue, administrator }

/// A per-portal accent palette.
///
/// NOTE ON PROVENANCE: the frozen `DESIGN.md` defines the shared "PetConnect
/// AI Core" palette exactly (see [AppColors]) but does **not** enumerate exact
/// per-portal accent hexes. Until each portal's screens are built and its
/// exact accent is read from Stitch, every portal defaults to the shared
/// authoritative primary. The structure below lets us swap in exact per-portal
/// seeds later **without touching any screen code** — only this file changes.
@immutable
class PortalPalette {
  const PortalPalette({
    required this.portal,
    required this.seed,
    required this.accent,
    required this.light,
    required this.dark,
  });

  final AppPortal portal;
  final Color seed;
  final Color accent;
  final ColorScheme light;
  final ColorScheme dark;

  /// Builds a portal palette from a seed by generating tonal schemes.
  ///
  /// When [seed] equals [AppColors.seed] the palettes fall back to the exact
  /// authoritative [AppColorScheme] rather than a generated approximation, so
  /// the default portal is pixel-faithful to the frozen spec.
  factory PortalPalette.fromSeed(AppPortal portal, Color seed) {
    final accent = accentFor(portal);
    if (seed == AppColors.seed) {
      return PortalPalette(
        portal: portal,
        seed: seed,
        accent: accent,
        light: AppColorScheme.light,
        dark: AppColorScheme.dark,
      );
    }
    return PortalPalette(
      portal: portal,
      seed: seed,
      accent: accent,
      light: ColorScheme.fromSeed(seedColor: seed),
      dark: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    );
  }

  /// The fixed brand accent for [portal], transcribed from the frozen Light
  /// Theme screen designs. Brand identity — constant across Light and Dark.
  static Color accentFor(AppPortal portal) => switch (portal) {
    AppPortal.petOwner => AppColors.petOwnerAccent,
    AppPortal.veterinarian => AppColors.veterinarianAccent,
    AppPortal.volunteerRescue => AppColors.volunteerRescueAccent,
    AppPortal.administrator => AppColors.administratorAccent,
  };

  /// The tinted "container" surface behind accent chips / badges / pills for
  /// this portal, resolved for [brightness].
  ///
  /// Light values are exact where Stitch provides them (Pet Owner
  /// `emerald-accent-container`); other portals and the dark variants are
  /// derived as hue-tinted tonal surfaces from [accent] so no screen invents
  /// a color. Consume via [context]-driven brightness, never hard-coded.
  Color accentContainer(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (portal == AppPortal.petOwner) {
      return isDark
          ? AppColors.petOwnerAccentContainerDark
          : AppColors.petOwnerAccentContainerLight;
    }
    return isDark
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.26),
            AppColors.darkSurfaceContainer,
          )
        : Color.alphaBlend(accent.withValues(alpha: 0.14), AppColors.white);
  }

  /// The foreground (icon/text) color that reads on [accentContainer] for the
  /// given [brightness].
  Color onAccentContainer(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (portal == AppPortal.petOwner) {
      return isDark ? AppColors.petOwnerOnAccentContainerDark : accent;
    }
    return isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.85), AppColors.white)
        : accent;
  }
}

/// Central registry of portal palettes.
///
/// All portals currently resolve to the shared authoritative palette. Replace
/// the seed for a portal here (or supply an exact [ColorScheme]) once its
/// design accent is confirmed from Stitch — no screen code changes required.
abstract final class PortalPalettes {
  const PortalPalettes._();

  // TODO(design): replace with exact per-portal seeds once confirmed from
  // Stitch during each portal's screen phase. Until then, shared seed.
  static final PortalPalette petOwner = PortalPalette.fromSeed(
    AppPortal.petOwner,
    AppColors.seed,
  );
  static final PortalPalette veterinarian = PortalPalette.fromSeed(
    AppPortal.veterinarian,
    AppColors.seed,
  );
  static final PortalPalette volunteerRescue = PortalPalette.fromSeed(
    AppPortal.volunteerRescue,
    AppColors.seed,
  );
  static final PortalPalette administrator = PortalPalette.fromSeed(
    AppPortal.administrator,
    AppColors.seed,
  );

  static PortalPalette of(AppPortal portal) => switch (portal) {
    AppPortal.petOwner => petOwner,
    AppPortal.veterinarian => veterinarian,
    AppPortal.volunteerRescue => volunteerRescue,
    AppPortal.administrator => administrator,
  };
}

/// Builds portal-scoped [ThemeData] by overlaying the portal's accent
/// [ColorScheme] onto the shared "Core" theme structure.
abstract final class PortalTheme {
  const PortalTheme._();

  static ThemeData light(AppPortal portal) {
    final palette = PortalPalettes.of(portal);
    if (palette.seed == AppColors.seed) return AppTheme.light;
    return AppTheme.light.copyWith(colorScheme: palette.light);
  }

  static ThemeData dark(AppPortal portal) {
    final palette = PortalPalettes.of(portal);
    if (palette.seed == AppColors.seed) return AppTheme.dark;
    return AppTheme.dark.copyWith(colorScheme: palette.dark);
  }
}
