/// Responsive breakpoints for the **PetConnect AI Core** design system.
///
/// Per frozen `DESIGN.md` layout spec:
/// - Mobile:  0 – 599px    (edge margin 20px)
/// - Tablet:  600 – 1023px (edge margin 32px)
/// - Desktop: 1024px+      (edge margin 40px)
///
/// The app is mobile-first; tablet/desktop are progressive enhancements.
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  /// Upper bound (exclusive) of the mobile range.
  static const double mobile = 600;

  /// Upper bound (exclusive) of the tablet range.
  static const double tablet = 1024;

  /// Lower bound of the large-desktop range.
  static const double desktop = 1440;

  /// Max readable content width for centered layouts.
  static const double maxContentWidth = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

/// Screen-size classification derived from [AppBreakpoints].

enum ScreenSize {
  mobile,
  tablet,
  desktop;

  static ScreenSize fromWidth(double width) {
    if (width < AppBreakpoints.mobile) return ScreenSize.mobile;
    if (width < AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}
