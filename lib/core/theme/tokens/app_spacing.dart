import 'package:flutter/widgets.dart';

/// Spacing scale for the **PetConnect AI Core** design system.
///
/// Verbatim from the frozen Stitch `DESIGN.md` `spacing` tokens. The scale
/// is a 4px base. Consume via these constants only — never hardcode raw
/// pixel gaps in widgets.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4px — atomic base unit.
  static const double base = 4;

  /// 8px.
  static const double xs = 8;

  /// 12px.
  static const double sm = 12;

  /// 16px — default internal card padding & grid gutter.
  static const double md = 16;

  /// 24px — vertical rhythm between major sections; premium card padding.
  static const double lg = 24;

  /// 32px.
  static const double xl = 32;

  /// 48px.
  static const double xxl = 48;

  /// 16px — grid gutter (mobile & tablet).
  static const double gutter = 16;

  /// 20px — screen edge margin on mobile (0–599px).
  static const double marginMobile = 20;

  /// 40px — screen edge margin on desktop (1024px+).
  static const double marginDesktop = 40;

  /// 32px — screen edge margin on tablet (600–1023px).
  static const double marginTablet = 32;

  // ── Convenience EdgeInsets ─────────────────────────────────────
  static const EdgeInsets screenPaddingMobile = EdgeInsets.symmetric(
    horizontal: marginMobile,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingPremium = EdgeInsets.all(lg);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    vertical: md,
    horizontal: md,
  );

  // ── Common SizedBox gaps ───────────────────────────────────────
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  static const SizedBox vGapXs = SizedBox(height: xs);
  static const SizedBox vGapSm = SizedBox(height: sm);
  static const SizedBox vGapMd = SizedBox(height: md);
  static const SizedBox vGapLg = SizedBox(height: lg);
  static const SizedBox vGapXl = SizedBox(height: xl);

  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
}
