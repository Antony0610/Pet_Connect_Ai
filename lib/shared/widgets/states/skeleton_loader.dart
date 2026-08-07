import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_durations.dart';
import '../../../core/theme/tokens/app_radius.dart';

/// A shimmering skeleton placeholder shown while content loads.
///
/// Compose these to build content-shaped loading states (a list of skeleton
/// rows that mirror the real layout). The shimmer animates between two
/// surface tones from the active [ColorScheme].
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    this.width,
    this.height = 16,
    this.borderRadius,
    this.isCircle = false,
    super.key,
  });

  /// A circular skeleton (e.g. avatar placeholder).
  const SkeletonLoader.circle({required double size, super.key})
    : width = size,
      height = size,
      borderRadius = null,
      isCircle = true;

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          colorScheme.surfaceContainerHighest,
          colorScheme.surfaceContainer,
          _controller.value,
        );
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : (widget.borderRadius ?? AppRadius.brMd),
          ),
        );
      },
    );
  }
}
