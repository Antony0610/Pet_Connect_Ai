import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../providers/auth_providers.dart';

/// Splash screen — the app's launch surface.
///
/// Mirrors the frozen Stitch splash design: a softly shifting lavender
/// gradient, drifting paw motifs, a glowing logo tile, the wordmark, tagline,
/// and pulsing loading dots. All colors resolve from the active [ColorScheme]
/// (frozen Light Theme); no literals.
///
/// While the entrance animation plays, [splashDestinationProvider] resolves
/// the real routing decision (session check + onboarding flag). Once BOTH the
/// minimum display duration has elapsed AND the decision is ready, the screen
/// navigates. This guarantees the branding is never a jarring flash.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Minimum time the splash stays visible so branding doesn't flash by.
  static const _minDisplay = Duration(milliseconds: 2200);

  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final Future<void> _minDelay;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _minDelay = Future<void>.delayed(_minDisplay);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Navigates to [destination] once the minimum display time has elapsed.
  Future<void> _goWhenReady(String destination) async {
    if (_navigated) return;
    await _minDelay;
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve routing off the min-display gate: navigate when both are ready.
    ref.listen(splashDestinationProvider, (previous, next) {
      next.whenData(_goWhenReady);
    });

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedGradientBackground(animation: _ambient),
          _FloatingPaws(animation: _ambient),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fadeScale(begin: 0.0, end: 0.6, child: const _LogoTile()),
                  const SizedBox(height: AppSpacing.xl),
                  _fadeSlide(begin: 0.2, end: 0.6, child: const _Wordmark()),
                  const SizedBox(height: AppSpacing.sm),
                  _fadeSlide(begin: 0.4, end: 0.8, child: const _Tagline()),
                  const SizedBox(height: AppSpacing.xxl),
                  _fadeSlide(
                    begin: 0.5,
                    end: 0.9,
                    child: _LoadingDots(animation: _ambient),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fade + upward slide entrance, staggered over [begin]..[end] of [_entrance].
  Widget _fadeSlide({
    required double begin,
    required double end,
    required Widget child,
  }) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Fade + gentle scale entrance for the logo.
  Widget _fadeScale({
    required double begin,
    required double end,
    required Widget child,
  }) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.scale(scale: 0.95 + 0.05 * anim.value, child: child),
      ),
      child: child,
    );
  }
}

/// Softly shifting lavender gradient, blended from frozen theme roles.
class _AnimatedGradientBackground extends StatelessWidget {
  const _AnimatedGradientBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = scheme.surface;
    final tintPrimary = Color.lerp(base, scheme.primaryContainer, 0.16)!;
    final tintTertiary = Color.lerp(base, scheme.tertiaryContainer, 0.12)!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value; // 0..1 looped
        final shift = math.sin(t * 2 * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1, -1 + 0.4 * shift),
              end: Alignment(1, 1 - 0.4 * shift),
              colors: [base, tintPrimary, tintTertiary, base],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// Three low-opacity paw glyphs drifting behind the content.
class _FloatingPaws extends StatelessWidget {
  const _FloatingPaws({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          _DriftingPaw(alignment: Alignment(-0.7, -0.6), size: 34, phase: 0.0),
          _DriftingPaw(alignment: Alignment(0.75, 0.5), size: 52, phase: 0.35),
          _DriftingPaw(alignment: Alignment(-0.6, 0.4), size: 26, phase: 0.7),
        ].map((paw) => _animate(context, paw)).toList(),
      ),
    );
  }

  Widget _animate(BuildContext context, _DriftingPaw paw) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value + paw.phase) % 1.0;
        final drift = math.sin(t * 2 * math.pi);
        return Align(
          alignment: paw.alignment,
          child: Opacity(
            opacity: 0.06 + 0.05 * (0.5 + 0.5 * drift),
            child: Transform.translate(
              offset: Offset(6 * drift, -14 * drift),
              child: Transform.rotate(angle: 0.25 * drift, child: child),
            ),
          ),
        );
      },
      child: Icon(
        Icons.pets,
        size: paw.size,
        color: context.colorScheme.primary,
      ),
    );
  }
}

/// Immutable descriptor for a single drifting paw.
class _DriftingPaw {
  const _DriftingPaw({
    required this.alignment,
    required this.size,
    required this.phase,
  });

  final Alignment alignment;
  final double size;
  final double phase;
}

/// The glowing rounded logo tile with the paw glyph.
class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  scheme.primary.withValues(alpha: 0.20),
                  scheme.primaryContainer.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Icon(Icons.pets, size: 74, color: scheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

/// The "PetConnect AI" wordmark.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'PetConnect AI',
      textAlign: TextAlign.center,
      style: context.textTheme.headlineLarge?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The splash tagline.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your AI-powered companion for smarter pet care.',
      textAlign: TextAlign.center,
      style: context.textTheme.bodyLarge?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Three pulsing dots hinting at background work.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = (animation.value + i * 0.2) % 1.0;
              final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.3 + 0.5 * pulse),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
