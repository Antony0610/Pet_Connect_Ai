import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for the **PetConnect AI Core** design system.
///
/// Family: **Inter** (per frozen `DESIGN.md`). Sizes follow the Material 3
/// type scale; weights are tuned for the "Expressive" variant — display &
/// headline are bold, titles semibold, body/label regular/medium.
///
/// This exposes a **geometry-only** [TextTheme] (no colors). Coloring is
/// applied by [ThemeData] from the active [ColorScheme] (`onSurface` etc.),
/// so the same scale serves both Light and Dark without duplication.
///
/// Consume via `Theme.of(context).textTheme.*` — never construct ad-hoc
/// [TextStyle]s with hardcoded sizes in widgets.
abstract final class AppTypography {
  const AppTypography._();

  /// Font family name, for callers that need the raw string.
  static const String fontFamily = 'Inter';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// The complete geometry [TextTheme], built on Inter.
  static TextTheme get textTheme => GoogleFonts.interTextTheme(_base);

  /// Geometry base (sizes / heights / spacing / weights) with no color.
  static const TextTheme _base = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      height: 64 / 57,
      letterSpacing: -0.25,
      fontWeight: bold,
    ),
    displayMedium: TextStyle(fontSize: 45, height: 52 / 45, fontWeight: bold),
    displaySmall: TextStyle(fontSize: 36, height: 44 / 36, fontWeight: bold),
    headlineLarge: TextStyle(fontSize: 32, height: 40 / 32, fontWeight: bold),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: semiBold,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: semiBold,
    ),
    titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: semiBold),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0.15,
      fontWeight: semiBold,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: medium,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0.5,
      fontWeight: regular,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.25,
      fontWeight: regular,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.4,
      fontWeight: regular,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: medium,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.5,
      fontWeight: medium,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.5,
      fontWeight: medium,
    ),
  );
}
