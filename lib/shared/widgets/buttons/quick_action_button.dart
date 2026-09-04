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

/// A modern, 3D-styled quick action button styled as an individual standalone elevated card tile
/// with multi-depth gradient icon container, realistic ambient drop shadow, and crisp centered label.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.isDanger = false,
    this.iconSize = 28,
    this.containerSize = 56,
    this.isCardTile = true,
  });

  factory QuickActionButton.fromSpec(
    QuickActionItemSpec spec, {
    double? containerSize,
    double? iconSize,
    bool isCardTile = true,
  }) {
    return QuickActionButton(
      title: spec.title,
      icon: spec.icon,
      gradientColors: spec.gradientColors,
      onTap: spec.onTap,
      badgeText: spec.badgeText,
      isDanger: spec.isDanger,
      containerSize: containerSize ?? 56,
      iconSize: iconSize ?? 28,
      isCardTile: isCardTile,
    );
  }

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isDanger;
  final double iconSize;
  final double containerSize;
  final bool isCardTile;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final primaryColor = gradientColors.first;
    final secondaryColor = gradientColors.length > 1 ? gradientColors[1] : gradientColors.first;

    final isCompact = containerSize <= 48;
    final content = Padding(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 4 : 14,
        horizontal: isCompact ? 3 : 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Elevated Squircle Icon Tile
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(primaryColor, Colors.white, 0.22) ?? primaryColor,
                      primaryColor,
                      secondaryColor,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                  boxShadow: [
                    // Soft colorful drop shadow for 3D depth
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.42),
                      blurRadius: isCompact ? 8 : 12,
                      offset: Offset(0, isCompact ? 3 : 5),
                      spreadRadius: -1,
                    ),
                    // Darker ambient contact shadow underneath
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Subtle top highlight reflection for glossy 3D effect
                    Positioned(
                      top: 1.5,
                      left: 3,
                      right: 3,
                      height: containerSize * 0.44,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(isCompact ? 12 : 16)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.38),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(icon, color: Colors.white, size: iconSize),
                    ),
                  ],
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 8 : 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 12),
          SizedBox(
            height: isCompact ? 26 : 34,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: AppTypography.bold,
                fontSize: isCompact ? 10.5 : 12.5,
                letterSpacing: -0.2,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );

    if (isCardTile) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: content,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: content,
      ),
    );
  }
}

/// A responsive, perfectly balanced Quick Actions Grid container that
/// distributes action buttons as separate individual standalone 3D card tiles
/// into strict uniform columns (e.g. 3 columns x 2 rows, or 4 columns).
class QuickActionsGridContainer extends StatelessWidget {
  const QuickActionsGridContainer({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
    this.tabletCrossAxisCount = 6,
    this.containerSize = 60,
    this.iconSize = 30,
    this.padding,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  final List<QuickActionItemSpec> items;
  final int crossAxisCount;
  final int tabletCrossAxisCount;
  final double containerSize;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 768;
    final cols = isDesktop ? tabletCrossAxisCount : crossAxisCount;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += cols) {
            final end = (i + cols < items.length) ? i + cols : items.length;
            final rowItems = items.sublist(i, end);

            rows.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var j = 0; j < rowItems.length; j++) ...[
                    if (j > 0) SizedBox(width: crossAxisSpacing),
                    Expanded(
                      child: QuickActionButton.fromSpec(
                        rowItems[j],
                        containerSize: containerSize,
                        iconSize: iconSize,
                        isCardTile: true,
                      ),
                    ),
                  ],
                  // Fill remaining space in partial rows if any
                  for (var k = 0; k < (cols - rowItems.length); k++) ...[
                    SizedBox(width: crossAxisSpacing),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            );

            if (end < items.length) {
              rows.add(SizedBox(height: mainAxisSpacing));
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: rows,
          );
        },
      ),
    );
  }
}
