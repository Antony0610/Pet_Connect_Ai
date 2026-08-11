import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/app_color_scheme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_elevation.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';

/// The **PetConnect AI Core** design-system theme.
///
/// Provides both Light and Dark [ThemeData] built from the centralized token
/// files. The Light theme is the authoritative master reference (frozen from
/// Stitch `DESIGN.md`); the Dark theme follows the established dark design
/// language and may be fine-tuned later.
///
/// Widgets consume theme properties via `Theme.of(context)` — never by
/// referencing raw token files directly.
abstract final class AppTheme {
  const AppTheme._();

  /// Light theme (master reference).
  static ThemeData get light => _buildTheme(
    colorScheme: AppColorScheme.light,
    brightness: Brightness.light,
  );

  /// Dark theme (tonal elevation, preserved accents).
  static ThemeData get dark => _buildTheme(
    colorScheme: AppColorScheme.dark,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      // ── Core scheme ────────────────────────────────────────────
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,

      // ── Typography ─────────────────────────────────────────────
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,

      // ── Elevation & surfaces ───────────────────────────────────
      applyElevationOverlayColor: isDark,

      // ── Component themes ───────────────────────────────────────
      // Card
      cardTheme: CardThemeData(
        elevation: AppElevation.level1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: isDark
            ? AppElevation.surfaceTintDark
            : AppElevation.surfaceTintLight,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        margin: EdgeInsets.zero,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: AppElevation.level2,
        surfaceTintColor: colorScheme.surfaceTint,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: AppElevation.level3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      ),

      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.level1,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        side: BorderSide(color: colorScheme.outline),
        labelStyle: AppTypography.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: AppElevation.level5,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSection),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppElevation.level4,
        modalElevation: AppElevation.level4,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brBottomSheet,
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: AppTypography.semiBold,
            );
          }
          return AppTypography.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppRadius.brMd,
        ),
        textStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Page transitions ───────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
