import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';

/// Component-level design tokens for buttons.
///
/// These map the raw token scale to button-specific sizing, padding, and
/// geometry. Consume via these constants rather than choosing raw token
/// values inline.
abstract final class ButtonTokens {
  const ButtonTokens._();

  // ── Height ─────────────────────────────────────────────────────
  static const double heightSmall = 36;
  static const double heightMedium = 44;
  static const double heightLarge = 52;

  // ── Padding ────────────────────────────────────────────────────
  static const EdgeInsets paddingSmall = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );
  static const EdgeInsets paddingMedium = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets paddingLarge = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  // ── Icon size (when button contains an icon) ───────────────────
  static const double iconSizeSmall = 18;
  static const double iconSizeMedium = 20;
  static const double iconSizeLarge = 24;

  static const double iconGap = AppSpacing.xs;

  // ── Radius ─────────────────────────────────────────────────────
  static const BorderRadius radius = AppRadius.brMd;
  static const BorderRadius radiusPill = AppRadius.brPill;
}
