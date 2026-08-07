import 'package:flutter/widgets.dart';

/// Corner-radius scale for the **PetConnect AI Core** design system.
///
/// Verbatim from the frozen Stitch `DESIGN.md` `rounded` tokens and the
/// Shapes section:
/// - Standard components (buttons, inputs): 8px
/// - Cards & containers: 16px (`rounded-lg`)
/// - Large content sections: 24px (`rounded-xl`)
/// - Avatars & chips: fully rounded (pill)
abstract final class AppRadius {
  const AppRadius._();

  /// 4px.
  static const double sm = 4;

  /// 8px — default (buttons, input fields).
  static const double md = 8;

  /// 12px.
  static const double lg = 12;

  /// 16px — cards & containers (`rounded-lg`).
  static const double xl = 16;

  /// 24px — large content sections (`rounded-xl`).
  static const double xxl = 24;

  /// 32px — modal sheets / confirmation surfaces (`rounded-[32px]`).
  static const double xxxl = 32;

  /// Fully rounded (pill) — avatars & chips.
  static const double full = 9999;

  // ── Convenience Radius ─────────────────────────────────────────
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rXxl = Radius.circular(xxl);
  static const Radius rXxxl = Radius.circular(xxxl);

  // ── Convenience BorderRadius ───────────────────────────────────
  static const BorderRadius brSm = BorderRadius.all(rSm);
  static const BorderRadius brMd = BorderRadius.all(rMd);
  static const BorderRadius brLg = BorderRadius.all(rLg);

  /// Card radius — 16px.
  static const BorderRadius brCard = BorderRadius.all(rXl);

  /// Large section radius — 24px.
  static const BorderRadius brSection = BorderRadius.all(rXxl);

  /// Pill radius for chips / avatars.
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(full));

  /// Top-only radius for bottom sheets — 24px.
  static const BorderRadius brBottomSheet = BorderRadius.vertical(top: rXxl);

  /// Full 32px radius — floating modal sheets / confirmation surfaces
  /// (`rounded-[32px]`).
  static const BorderRadius brModal = BorderRadius.all(rXxxl);

  /// Top-only 32px radius — modal sheets docked to the bottom on mobile
  /// (`rounded-t-[32px]`).
  static const BorderRadius brModalTop = BorderRadius.vertical(top: rXxxl);
}
