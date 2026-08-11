import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Discover Feed** (Light
/// Theme design authority, ID `5aa424a6`).
///
/// Provides topic category exploration, featured AI-verified health guides,
/// user success stories, and community feed cards.
class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTopic = 'All Topics';

  final List<String> _topics = const [
    'All Topics',
    'Success Stories',
    'Health & Diet',
    'Training Tips',
    'Local Events',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Discover',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Search topics...')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Topic Filter Chips ─────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _topics.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (context, index) {
                      final topic = _topics[index];
                      final isSelected = _selectedTopic == topic;
                      return ChoiceChip(
                        label: Text(topic),
                        selected: isSelected,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedTopic = topic);
                        },
                      );
                    },
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Featured AI Verified Guide ─────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: scheme.primary, size: 18),
                          AppSpacing.hGapXs,
                          Text(
                            'AI Verified',
                            style: context.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          Text(
                            ' • Nutrition Guide',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'The Optimal Raw Diet Transition for Senior Dogs',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Transitioning an older dog to a raw diet requires careful consideration of their changing digestive needs and nutrient requirements. Our AI veterinarian outlines a safe, phased approach to introducing fresh foods.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: scheme.primary,
                            size: 18,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            'PetConnect Health AI',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          const Spacer(),
                          AppButton.filled(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Raw Diet Transition Guide...',
                                  ),
                                ),
                              );
                            },
                            size: AppButtonSize.small,
                            child: const Text('Read Full Guide'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── User Post Card ─────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const UserAvatar(name: 'Sarah & Max', radius: 18),
                          AppSpacing.hGapSm,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sarah & Max',
                                style: context.textTheme.labelLarge?.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              Text(
                                '2 hrs ago • Training',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Text(
                        'Leash reactivity breakthrough!',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        "After 3 months of consistent counter-conditioning, Max finally walked past another dog without barking. The 'look at me' command we learned from the AI module was a game changer.",
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border, size: 18),
                            onPressed: () {},
                          ),
                          Text('24', style: context.textTheme.labelMedium),
                          AppSpacing.hGapMd,
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            onPressed: () {},
                          ),
                          Text('8', style: context.textTheme.labelMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, size: 18),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Success Story Card ─────────────────────────────
                AppCard(
                  backgroundColor: scheme.tertiaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: scheme.tertiary, size: 18),
                          AppSpacing.hGapXs,
                          Text(
                            'Success Story',
                            style: context.textTheme.labelLarge?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        "Luna's Recovery Journey",
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Read how community support and AI-driven physical therapy routines helped Luna regain her mobility after surgery. A story of resilience and premium care.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      AppButton.outlined(
                        onPressed: () {},
                        size: AppButtonSize.small,
                        child: const Text('Read Story'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
