import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Component-level design tokens for input fields.
abstract final class InputTokens {
  const InputTokens._();

  // ── Height ─────────────────────────────────────────────────────
  static const double heightSmall = 40;
  static const double heightMedium = 48;
  static const double heightLarge = 56;

  // ── Padding ────────────────────────────────────────────────────
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.md,
  );

  // ── Radius ─────────────────────────────────────────────────────
  static const BorderRadius radius = AppRadius.brMd;

  // ── Border width ───────────────────────────────────────────────
  static const double borderWidthDefault = 1;
  static const double borderWidthFocused = 2;

  // ── Icon size (prefix/suffix icons) ────────────────────────────
  static const double iconSize = 20;
  static const double iconGap = AppSpacing.sm;

  // ── Label / helper spacing ─────────────────────────────────────
  static const double labelGap = AppSpacing.xs;
}
