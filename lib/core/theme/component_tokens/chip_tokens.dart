import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Component-level design tokens for chips.
abstract final class ChipTokens {
  const ChipTokens._();

  // ── Height ─────────────────────────────────────────────────────
  static const double heightSmall = 24;
  static const double heightMedium = 32;

  // ── Padding ────────────────────────────────────────────────────
  static const EdgeInsets paddingSmall = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: 4,
  );
  static const EdgeInsets paddingMedium = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );

  // ── Radius ─────────────────────────────────────────────────────
  static const BorderRadius radius = AppRadius.brPill;

  // ── Icon size ──────────────────────────────────────────────────
  static const double iconSize = 16;
  static const double avatarSize = 24;

  // ── Gap ────────────────────────────────────────────────────────
  static const double gap = AppSpacing.xs;
}
