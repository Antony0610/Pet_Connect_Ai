import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';

/// Component-level design tokens for cards.
abstract final class CardTokens {
  const CardTokens._();

  // ── Padding ────────────────────────────────────────────────────
  /// Default internal padding.
  static const EdgeInsets padding = EdgeInsets.all(AppSpacing.md);

  /// Premium card padding (larger surface).
  static const EdgeInsets paddingPremium = EdgeInsets.all(AppSpacing.lg);

  /// Compact card padding (dense lists).
  static const EdgeInsets paddingCompact = EdgeInsets.all(AppSpacing.sm);

  // ── Radius ─────────────────────────────────────────────────────
  static const BorderRadius radius = AppRadius.brCard;

  // ── Gap between cards in a list ────────────────────────────────
  static const double gap = AppSpacing.md;
}
