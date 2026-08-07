/// Icon-size tokens for the **PetConnect AI Core** design system.
///
/// Per frozen `DESIGN.md`: icons align to the 4px grid; 24px is the default
/// touch-target icon, 20px for dense contexts, 16px inline with text.
abstract final class AppIconSizes {
  const AppIconSizes._();

  /// 16px — inline with body text, chips.
  static const double xs = 16;

  /// 20px — dense lists, secondary actions.
  static const double sm = 20;

  /// 24px — default (app bar, bottom nav, buttons).
  static const double md = 24;

  /// 32px — prominent actions, section headers.
  static const double lg = 32;

  /// 40px — feature highlights.
  static const double xl = 40;

  /// 48px — empty-state / hero illustrations glyphs.
  static const double xxl = 48;
}
