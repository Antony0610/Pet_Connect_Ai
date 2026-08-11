import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

/// Post-verification celebration screen.
///
/// Confetti + a pulsing glow behind a hero illustration, with staggered
/// entrance animations for the copy and CTA. Every color resolves through the
/// active [ColorScheme]; the confetti palette mixes the theme's primary family
/// with the Pet Owner emerald accent, matching the frozen Light Theme design.
class WelcomeSuccessScreen extends ConsumerStatefulWidget {
  const WelcomeSuccessScreen({super.key});

  @override
  ConsumerState<WelcomeSuccessScreen> createState() =>
      _WelcomeSuccessScreenState();
}

class _WelcomeSuccessScreenState extends ConsumerState<WelcomeSuccessScreen>
    with TickerProviderStateMixin {
  static const String _illustrationUrl =
      'https://lh3.googleusercontent.com/aida/'
      'AP1WRLsgODWAZ3qyQjpyUZpvwbORzGObbpQpPZW0AdFwGoC5ny-tj_3-HcmAz_M8s3kp8nhlvwrABSP3OGIig9uCEhfQJqqUAyfNzZvW8hqtQVsIoPJxwIGiK4zu7BZPfxuVAfklLFpIiZlMvo4ayOWhOaPDoLMtEdcVdP4H8C9bHmjlEWcvAEicLCkxuaYfvHM17XGUyjW9XXMHC9DaXsFLp0tKr-7iEqowDj6gkEKr9nLyo3HxkLVVNUU8ak4';

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Interval _interval(double start, double end) =>
      Interval(start, end, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final emerald = PortalPalettes.of(AppPortal.petOwner).accent;
    final confettiColors = <Color>[
      scheme.primary,
      scheme.primaryContainer,
      scheme.tertiary,
      emerald,
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _ambient.value,
                    colors: confettiColors,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroIllustration(
                        entrance: _entrance,
                        ambient: _ambient,
                        url: _illustrationUrl,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _FadeUp(
                        controller: _entrance,
                        interval: _interval(0.30, 0.70),
                        child: Text(
                          'Welcome to PetConnect AI',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FadeUp(
                        controller: _entrance,
                        interval: _interval(0.45, 0.85),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            'Your account has been successfully created.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _FadeUp(
                        controller: _entrance,
                        interval: _interval(0.60, 1.0),
                        child: AppButton.filled(
                          label: 'Continue',
                          icon: Icons.arrow_forward,
                          iconAlignment: IconAlignment.end,
                          isFullWidth: true,
                          size: AppButtonSize.large,
                          borderRadius: BorderRadius.circular(9999),
                          onPressed: () =>
                              context.go(RoutePaths.initialPetSetup),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero illustration with a pop-in entrance and a slow pulsing glow.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({
    required this.entrance,
    required this.ambient,
    required this.url,
  });

  final AnimationController entrance;
  final AnimationController ambient;
  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final pop = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0, 0.6, curve: Curves.elasticOut),
    );
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: Listenable.merge([entrance, ambient]),
        builder: (context, child) {
          final glow = 0.3 + (0.2 * math.sin(ambient.value * 2 * math.pi));
          final glowScale = 1.1 + (0.1 * math.sin(ambient.value * 2 * math.pi));
          return Transform.scale(
            scale: (0.8 + 0.2 * pop.value).clamp(0.0, 1.0),
            child: Opacity(
              opacity: entrance.value.clamp(0.0, 1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: glowScale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            scheme.primaryContainer.withValues(alpha: glow),
                            scheme.primaryContainer.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.celebration_outlined,
              size: 120,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides its [child] up as [controller] crosses [interval].
class _FadeUp extends StatelessWidget {
  const _FadeUp({
    required this.controller,
    required this.interval,
    required this.child,
  });

  final AnimationController controller;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: controller, curve: interval);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Lightweight falling-confetti backdrop. Deterministic per-piece motion keyed
/// off a single repeating [progress] value — no per-frame allocation.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors})
    : _random = math.Random(7);

  final double progress;
  final List<Color> colors;
  final math.Random _random;

  static const int _pieceCount = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _pieceCount; i++) {
      final left = _random.nextDouble();
      final pieceSize = 6 + _random.nextDouble() * 10;
      final speed = 0.6 + _random.nextDouble() * 0.8;
      final phase = _random.nextDouble();
      final color = colors[i % colors.length];

      final t = (progress * speed + phase) % 1.0;
      final dx = left * size.width;
      final dy = t * (size.height + 120) - 60;
      final rotation = t * math.pi * 4;
      final opacity = (1 - t) * 0.8;

      paint.color = color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      final isRound = i % 3 == 0;
      if (isRound) {
        canvas.drawCircle(Offset.zero, pieceSize / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: pieceSize,
            height: pieceSize * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
