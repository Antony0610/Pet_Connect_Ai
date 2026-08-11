import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_durations.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

/// Immutable content for a single onboarding page.
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;
}

const _pages = <_OnboardingPageData>[
  _OnboardingPageData(
    image: 'assets/illustrations/onboarding_1.jpg',
    title: 'Love your pets smarter.',
    subtitle: "Your intelligent companion for every moment of your pet's life.",
  ),
  _OnboardingPageData(
    image: 'assets/illustrations/onboarding_2.jpg',
    title: 'Always know where they are.',
    subtitle:
        'Real-time Smart Collar tracking with GPS, Wi-Fi, BLE and '
        'GSM/LTE.',
  ),
  _OnboardingPageData(
    image: 'assets/illustrations/onboarding_3.jpg',
    title: 'Health powered by AI.',
    subtitle: 'Health Passport, AI analysis and smarter care in one place.',
  ),
  _OnboardingPageData(
    image: 'assets/illustrations/onboarding_4.jpg',
    title: 'Everything your pet needs.',
    subtitle: 'The complete ecosystem for your best friend.',
  ),
];

/// Onboarding carousel — the app's value proposition across four pages.
///
/// Mirrors the frozen Stitch onboarding design: a glass top bar with a Skip
/// action, a swipeable illustration/headline/subtitle carousel, animated dot
/// indicators, and circular prev/next controls. The final page swaps the
/// controls for the primary "Get Started" and secondary "I Already Have an
/// Account" actions.
///
/// Reaching either final action persists the onboarding-complete flag via
/// [CompleteOnboarding] so the flow is never shown again, then routes into the
/// auth flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLastPage => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
    _controller.animateToPage(
      page,
      duration: AppDurations.medium2,
      curve: AppDurations.standard,
    );
  }

  void _next() {
    if (_index < _pages.length - 1) _animateTo(_index + 1);
  }

  void _previous() {
    if (_index > 0) _animateTo(_index - 1);
  }

  void _skip() => _animateTo(_pages.length - 1);

  /// Persists completion (best-effort) then routes to [destination].
  Future<void> _finish(String destination) async {
    final result = await ref.read(completeOnboardingProvider)(const NoParams());
    result.fold(
      (failure) => ref
          .read(loggerProvider)
          .warning('Failed to persist onboarding flag: ${failure.message}'),
      (_) {},
    );
    if (!mounted) return;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _GlassHeader(showSkip: !_isLastPage, onSkip: _skip),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPage(
                  data: _pages[i],
                  isLast: i == _pages.length - 1,
                  onGetStarted: () => _finish(RoutePaths.roleSelection),
                  onHaveAccount: () => _finish(RoutePaths.login),
                ),
              ),
            ),
            _OnboardingFooter(
              pageCount: _pages.length,
              index: _index,
              isLastPage: _isLastPage,
              onNext: _next,
              onPrevious: _previous,
              onDotTap: _animateTo,
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass top bar: brand mark + Skip action.
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.pets, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'PetConnect AI',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Skip is hidden on the last page (fades out when leaving).
          AnimatedOpacity(
            opacity: showSkip ? 1 : 0,
            duration: AppDurations.short4,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single onboarding page: illustration, headline, subtitle, and — on the
/// final page — the primary/secondary calls to action.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isLast,
    required this.onGetStarted,
    required this.onHaveAccount,
  });

  final _OnboardingPageData data;
  final bool isLast;
  final VoidCallback onGetStarted;
  final VoidCallback onHaveAccount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 340),
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Icon(
                Icons.pets,
                size: 120,
                color: context.colorScheme.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: context.textTheme.displaySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isLast) ...[
            const SizedBox(height: AppSpacing.xxl),
            AppButton.filled(
              label: 'Get Started',
              icon: Icons.arrow_forward,
              isFullWidth: true,
              size: AppButtonSize.large,
              onPressed: onGetStarted,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.outlined(
              label: 'I Already Have an Account',
              isFullWidth: true,
              size: AppButtonSize.large,
              onPressed: onHaveAccount,
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom controls: animated dot indicators + circular prev/next buttons.
///
/// On the final page the nav controls collapse (the page's own CTAs take
/// over), leaving only the indicators.
class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.pageCount,
    required this.index,
    required this.isLastPage,
    required this.onNext,
    required this.onPrevious,
    required this.onDotTap,
  });

  final int pageCount;
  final int index;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (i) => _Dot(isActive: i == index, onTap: () => onDotTap(i)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSize(
            duration: AppDurations.medium2,
            curve: AppDurations.standard,
            child: isLastPage
                ? const SizedBox(width: double.infinity)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        isPrimary: false,
                        // Prev is invisible & inert on the first page.
                        onPressed: index == 0 ? null : onPrevious,
                      ),
                      _CircleButton(
                        icon: Icons.arrow_forward,
                        isPrimary: true,
                        onPressed: onNext,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single tappable page-indicator dot; the active dot elongates.
class _Dot extends StatelessWidget {
  const _Dot({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium2,
        curve: AppDurations.standard,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        width: isActive ? 32 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}

/// Circular navigation control. The primary (next) variant is larger and
/// filled; the secondary (prev) variant is tonal and hides when disabled.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = isPrimary ? 64.0 : 48.0;
    final disabled = onPressed == null;

    return AnimatedOpacity(
      opacity: disabled ? 0 : 1,
      duration: AppDurations.short4,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: isPrimary ? scheme.primary : scheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(
              icon,
              size: isPrimary ? 32 : 24,
              color: isPrimary ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
