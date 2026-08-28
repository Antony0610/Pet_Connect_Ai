import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Pet Adoption Hub** connecting pet owners and prospective adopters
/// with local rescue shelter candidates and AI compatibility scores.
class PetAdoptionScreen extends StatefulWidget {
  const PetAdoptionScreen({super.key});

  @override
  State<PetAdoptionScreen> createState() => _PetAdoptionScreenState();
}

class _PetAdoptionScreenState extends State<PetAdoptionScreen> {
  static const double _maxContentWidth = 1100;
  String _selectedCategory = 'Dogs';
  String _searchQuery = '';
  final Set<String> _favoritePetIds = {'adopt-1'};

  final List<String> _categories = const ['Dogs', 'Cats', 'Puppies', 'All'];

  final List<_AdoptionCandidate> _allCandidates = [
    const _AdoptionCandidate(
      id: 'adopt-1',
      name: 'Bella',
      age: '2 yrs',
      species: 'Dog',
      breed: 'Golden Retriever',
      matchScore: 98,
      shelter: 'Sunnyvale Animal Rescue',
      distance: '2.5 mi away',
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800',
      personality: ['Gentle', 'Kid Friendly', 'Active'],
      description: 'Loving, gentle, and highly trainable. Thrives with daily walks and a caring family.',
    ),
    const _AdoptionCandidate(
      id: 'adopt-2',
      name: 'Oliver',
      age: '3 mos',
      species: 'Cat',
      breed: 'Short-hair Tabby',
      matchScore: 94,
      shelter: 'Bay Area Feline Friends',
      distance: '3.8 mi away',
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
      personality: ['Playful', 'Affectionate', 'Litter Trained'],
      description: 'Energetic kitten who loves climbing and catnip toys. Gets along great with other pets.',
    ),
    const _AdoptionCandidate(
      id: 'adopt-3',
      name: 'Charlie',
      age: '4 mos',
      species: 'Dog',
      breed: 'Beagle Mix Puppy',
      matchScore: 89,
      shelter: 'Humane Animal Alliance',
      distance: '5.1 mi away',
      imageUrl: 'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=800',
      personality: ['Curious', 'Food Motivated', 'Social'],
      description: 'Sweet Beagle puppy with a keen nose for adventure. Vaccinated and ready for home.',
    ),
    const _AdoptionCandidate(
      id: 'adopt-4',
      name: 'Luna',
      age: '1 yr',
      species: 'Cat',
      breed: 'Calico Cat',
      matchScore: 91,
      shelter: 'Valley Pet Haven',
      distance: '4.2 mi away',
      imageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=800',
      personality: ['Calm', 'Independent', 'Cuddle Bug'],
      description: 'Quiet and sweet companion who enjoys sunny window sills and gentle scratches.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    final filteredCandidates = _allCandidates.where((pet) {
      if (_selectedCategory == 'Dogs' && pet.species != 'Dog') return false;
      if (_selectedCategory == 'Cats' && pet.species != 'Cat') return false;
      if (_selectedCategory == 'Puppies' && !pet.age.contains('mos')) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return pet.name.toLowerCase().contains(q) ||
            pet.breed.toLowerCase().contains(q) ||
            pet.shelter.toLowerCase().contains(q);
      }
      return true;
    }).toList();

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
            icon: Badge(
              label: Text('${_favoritePetIds.length}'),
              isLabelVisible: _favoritePetIds.isNotEmpty,
              child: const Icon(Icons.favorite),
            ),
            tooltip: 'Saved Favorites',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_favoritePetIds.length} pets saved to your adoption favorites'),
                ),
              );
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'AI Companion Matcher',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Matches shelter pets with your lifestyle, living space, and activity level.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search by breed, age, or shelter location...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark
                              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                              : scheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
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
                          if (selected) {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Recommended Matches ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Recommended Matches',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      '${filteredCandidates.length} Available',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                if (filteredCandidates.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 40,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          AppSpacing.vGapSm,
                          Text(
                            'No matching pets found',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Try selecting "All" or updating your search query.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final pet in filteredCandidates) ...[
                    _buildPetAdoptionCard(context, pet),
                    AppSpacing.vGapMd,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetAdoptionCard(BuildContext context, _AdoptionCandidate pet) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final isFav = _favoritePetIds.contains(pet.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet Header Image / Visual Hero
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  pet.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    child: Center(
                      child: Icon(Icons.pets, size: 50, color: scheme.primary),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${pet.matchScore}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isFav) {
                        _favoritePetIds.remove(pet.id);
                      } else {
                        _favoritePetIds.add(pet.id);
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${pet.name}, ${pet.age}',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      pet.breed,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    Icon(Icons.home_work_outlined, size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${pet.shelter} • ${pet.distance}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                Text(
                  pet.description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pet.personality.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: isDark ? 0.3 : 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapMd,
                SizedBox(
                  width: double.infinity,
                  child: AppButton.filled(
                    onPressed: () => _showInquireSheet(context, pet),
                    child: Text('Inquire About ${pet.name}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInquireSheet(BuildContext context, _AdoptionCandidate pet) {
    HapticFeedback.lightImpact();
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adoption Inquiry: ${pet.name}',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              'Sending application inquiry directly to ${pet.shelter}.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message to Shelter',
                hintText: 'Introduce your home, family, and experience with pets...',
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.vGapMd,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Adoption Application'),
                onPressed: () {
                  Navigator.pop(ctx);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Inquiry sent to ${pet.shelter}! They will reach out shortly.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdoptionCandidate {
  const _AdoptionCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.species,
    required this.breed,
    required this.matchScore,
    required this.shelter,
    required this.distance,
    required this.imageUrl,
    required this.personality,
    required this.description,
  });

  final String id;
  final String name;
  final String age;
  final String species;
  final String breed;
  final int matchScore;
  final String shelter;
  final String distance;
  final String imageUrl;
  final List<String> personality;
  final String description;
}
