import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';

/// Spec for a Quick Action item across the app.
class QuickActionItemSpec {
  const QuickActionItemSpec({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.isDanger = false,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isDanger;
}

/// A modern, compact quick action button styled with a vibrant gradient container,
/// subtle 3D drop shadow, and crisp centered label — matching the reference design.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.isDanger = false,
    this.iconSize = 22,
    this.containerSize = 46,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isDanger;
  final double iconSize;
  final double containerSize;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (badgeText != null && badgeText!.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDanger ? scheme.error : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: AppTypography.semiBold,
                fontSize: 11,
                letterSpacing: -0.2,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
