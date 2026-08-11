import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Pet Adoption** (Light
/// Theme design authority, ID `9a5cc91d`).
///
/// Provides AI-driven companion matching, lifestyle compatibility scoring,
/// search filters, and adoption shelter profiles.
class PetAdoptionScreen extends StatefulWidget {
  const PetAdoptionScreen({super.key});

  @override
  State<PetAdoptionScreen> createState() => _PetAdoptionScreenState();
}

class _PetAdoptionScreenState extends State<PetAdoptionScreen> {
  static const double _maxContentWidth = 1100;
  String _selectedCategory = 'Dogs';

  final List<String> _categories = const ['Dogs', 'Cats', 'Puppies', 'Near Me'];

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
          'Adopt a Pet',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Saved Favorites',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('2 saved pets')));
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
                // ── Hero Section / Search Bar ─────────────────────
                AiGradientBorderCard(
                  child: Column(
                    children: [
                      Text(
                        'Find Your Perfect Companion',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Our AI matches you with pets looking for a forever home based on your lifestyle and preferences.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      const AppTextField(
                        hintText: 'Search by breed, age, or location...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
                Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(cat),
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
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Recommended Bento Layout Grid ───────────────
                const SectionHeader(title: 'AI Recommended Matches'),
                AppSpacing.vGapSm,
                _buildBentoGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildFeaturedPetCard(
                  context,
                  name: 'Bella, 2 yrs',
                  breed: 'Golden Retriever',
                  match: 98,
                  shelter: 'Sunnyvale Shelter (2.5 mi away)',
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSecondaryPetCard(
                      context,
                      name: 'Oliver, 3 mos',
                      breed: 'Cat • Tabby',
                      match: 92,
                    ),
                    AppSpacing.vGapMd,
                    _buildSecondaryPetCard(
                      context,
                      name: 'Charlie, 7 yrs',
                      breed: 'Dog • Beagle Mix',
                      match: 85,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildFeaturedPetCard(
              context,
              name: 'Bella, 2 yrs',
              breed: 'Golden Retriever',
              match: 98,
              shelter: 'Sunnyvale Shelter (2.5 mi away)',
            ),
            AppSpacing.vGapMd,
            _buildSecondaryPetCard(
              context,
              name: 'Oliver, 3 mos',
              breed: 'Cat • Tabby',
              match: 92,
            ),
            AppSpacing.vGapMd,
            _buildSecondaryPetCard(
              context,
              name: 'Charlie, 7 yrs',
              breed: 'Dog • Beagle Mix',
              match: 85,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedPetCard(
    BuildContext context, {
    required String name,
    required String breed,
    required int match,
    required String shelter,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.pets, size: 80, color: scheme.onPrimaryContainer),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AiConfidenceBadge(percentage: '$match%'),
                    AppSpacing.hGapXs,
                    Text(
                      breed,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                Text(
                  name,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  shelter,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapMd,
                AppButton.filled(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Inquiring about adopting $name...'),
                      ),
                    );
                  },
                  size: AppButtonSize.small,
                  child: const Text('Inquire About Adoption'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryPetCard(
    BuildContext context, {
    required String name,
    required String breed,
    required int match,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.pets,
              size: 28,
              color: scheme.onSecondaryContainer,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [AiConfidenceBadge(percentage: '$match%')]),
                Text(
                  name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  breed,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }
}
