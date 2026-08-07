import 'package:flutter/animation.dart';

/// Motion tokens for the **PetConnect AI Core** design system.
///
/// Per frozen `DESIGN.md`: motion is quick and easy, emphasized-easing for
/// entrances, standard-easing for small state changes. Durations follow the
/// Material 3 motion spec.
///
/// Consume these instead of hardcoding `Duration`/`Curve` literals so the
/// whole app shares one motion language.
abstract final class AppDurations {
  const AppDurations._();

  // ── Duration scale (M3) ────────────────────────────────────────

  /// 50ms — micro state (ripple start, tiny toggles).
  static const Duration short1 = Duration(milliseconds: 50);

  /// 100ms.
  static const Duration short2 = Duration(milliseconds: 100);

  /// 150ms — small utility transitions.
  static const Duration short3 = Duration(milliseconds: 150);

  /// 200ms — default control transitions (buttons, switches).
  static const Duration short4 = Duration(milliseconds: 200);

  /// 250ms.
  static const Duration medium1 = Duration(milliseconds: 250);

  /// 300ms — default component enter/exit.
  static const Duration medium2 = Duration(milliseconds: 300);

  /// 350ms.
  static const Duration medium3 = Duration(milliseconds: 350);

  /// 400ms — expressive component transitions.
  static const Duration medium4 = Duration(milliseconds: 400);

  /// 450ms — page / route transitions.
  static const Duration long1 = Duration(milliseconds: 450);

  /// 500ms — large surface transitions (bottom sheets, full-screen).
  static const Duration long2 = Duration(milliseconds: 500);

  /// 700ms — skeleton shimmer loop.
  static const Duration shimmer = Duration(milliseconds: 700);

  // ── Curves (M3 easing) ─────────────────────────────────────────

  /// Standard easing — most transitions.
  static const Curve standard = Curves.easeInOutCubicEmphasized;

  /// Decelerate — entering elements.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Accelerate — exiting elements.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Linear — progress indicators, shimmer.
  static const Curve linear = Curves.linear;
}
